using LightXML, GraphNeuralNetworks, Flux

using Flux: onehotbatch
using LightXML


function onehot_encoder(data, categories)
    return onehotbatch(data, categories)
end


function get_elements(xroot)
    es = []
    for c in child_nodes(xroot)  # c is an instance of XMLNode
        if is_elementnode(c)
            e = XMLElement(c)  # this makes an XMLElement instance
            push!(es, e)
        end
    end
    es
end


function parse_graphml(file::String = "1.graphml")
    xdoc = parse_file(file)
    xroot = root(xdoc)
    graph = first(filter(e -> name(e) == "graph", get_elements(xroot)))
    nodes = filter(e -> name(e) == "node", get_elements(graph))
    node_dicts = Vector{Dict{String, String}}()
    for node in nodes
        id = attribute(node, "id")
        data = first(filter(e -> name(e) == "data", get_elements(node)))
        label = content(first(child_nodes(data)))
        push!(node_dicts, Dict("id" => id, "label" => label))
    end
    edges = filter(e -> name(e) == "edge", get_elements(graph))

    edge_dicts = Vector{Dict{String, String}}()
    for edge in edges
        source = attribute(edge, "source")
        target = attribute(edge, "target")
        data = first(filter(e -> name(e) == "data", get_elements(edge)))
        label = content(first(child_nodes(data)))
        push!(edge_dicts, Dict("source" => source, "target" => target, "label" => label))
    end
    free(xdoc)
    node_dicts, edge_dicts
end


struct TempGraph
    sources::Vector{Int}
    targets::Vector{Int}
    ndata::Matrix{Float64}
    edata::Matrix{Float64}
end

function TempGraph(
  node_dicts::Vector{Dict{String, String}}, 
  edge_dicts::Vector{Dict{String, String}}
)::TempGraph

    # Collect unique node ids
    node_ids = unique([node["id"] for node in node_dicts])

    # Create a mapping from original ids to integer ids
    id_mapping = Dict(node_ids[i] => i for i in eachindex(node_ids))

    # Create edges in both directions
    sources = [id_mapping[edge["source"]] for edge in edge_dicts]
    targets = [id_mapping[edge["target"]] for edge in edge_dicts]
    edata = [edge["label"] for edge in edge_dicts]

    # Concatenate original edges and reverse edges
    sources_new = vcat(sources, targets)
    targets_new = vcat(targets, sources)
    edata_new = vcat(edata, edata)

    TempGraph(
        sources_new,
        targets_new,
        onehot_encoder([node["label"] for node in node_dicts], ["0", "1", "1_start", "0_start", "P"]),
        onehot_encoder(edata_new, ["0", "1", "01", "P", "0P", "1P", "01P"])
    )
end

function TempGraph(file::String = "1.graphml")
    node_dicts, edge_dicts = parse_graphml(file)
    TempGraph(node_dicts, edge_dicts)
end

function GraphNeuralNetworks.GNNGraph(tg::TempGraph)
    GNNGraph(
        tg.sources,
        tg.targets;
        ndata = tg.ndata,
        edata = tg.edata,
    )
end

function gnn_from_graphml(file::String = "1.graphml")
    tg = TempGraph(file)
    GraphNeuralNetworks.GNNGraph(tg)
end

using Glob

function get_gnns_from_directory(; dir::String = "data/fsms/", r::UnitRange{Int} = 1:10)
    # Find all graphml files in the directory within the given range
    files = glob("*.graphml", dir)

    # Filter files based on the unitrange
    files_in_range = filter(file -> parse(Int, splitext(basename(file))[1]) ∈ r, files)
    
    # Create GNNGraph for each file and return as a vector
    return [gnn_from_graphml(file) for file in files_in_range]
end


using CSV, DataFrames

struct GEDTrainPair
    g1::GNNGraph
    g2::GNNGraph
    dists::Dict{String, Float32}
end

function normalize_data(vec::Vector{<:Real})
    vec = [Float32(x) for x in vec]
    mean_val = mean(vec)
    std_val = std(vec)
    return (vec .- mean_val) ./ std_val
end

function load_graphs_vec(graphdir::String)
    # Load all graphs in order into a vector of GNNGraphs
    files = glob("*.graphml", graphdir)
    sorted_files = sort(files, by = file -> parse(Int, splitext(basename(file))[1]))
    return [gnn_from_graphml(file) for file in ProgressBar(sorted_files)]
end

function load_graphs_in_range(directory, range)
    files = readdir(directory)
    # Filter only .graphml files and sort them based on their integer names
    files = sort([file for file in files if occursin(".graphml", file)], by = file -> parse(Int, split(file, ".")[1]))

    loaded_files = []
    for i in ProgressBar(1:range:length(files))
        filename = joinpath(directory, files[i])
        if isfile(filename)
            graph = gnn_from_graphml(file)
            push!(loaded_files, graph)
        end
    end
    return loaded_files
end


function load_graphs_and_make_pairs(graphdir::String, csv_file::String, ignore_singleton_pairs::Bool = false)
    # Load all graphs in order into a vector of GNNGraphs
    graphs = load_graphs(graphdir)
    
    # Load CSV data
    csv_data = CSV.read(csv_file, DataFrame)
    
    # Create GEDTrainPairs
    pairs = GEDTrainPair[]  # Initialize an empty array for GEDTrainPairs
    normdists = normalize_data([row[:dist] for row in eachrow(csv_data)])
    
    for (row, normdist) in ProgressBar(zip(eachrow(csv_data), normdists))
        left_index = row[:left]
        right_index = row[:right]
        dist = Float32(row[:dist])
        g1 = graphs[left_index]
        g2 = graphs[right_index]
        if ignore_singleton_pairs &&  g1.num_nodes == 2 && g2.num_nodes == 2
            continue
        end
        scaledist = Float32(dist / ((g1.num_nodes + g2.num_nodes) / 2))
        # Julia array indices start at 1, so adjust if your file names start at 0
        dists = Dict("raw" => dist, "scale" => scaledist, "norm" => normdist)
        pair = GEDTrainPair(graphs[left_index], graphs[right_index], dists)
        push!(pairs, pair)
    end
    
    return pairs
end

function load_graphs(graphdir::String)
    # Load all graphs in order into a vector of GNNGraphs
    loaddir = joinpath(ENV["DATA_DIR"], graphdir)
    files = glob("*.graphml", loaddir)
    sorted_files = sort(files, by = file -> parse(Int, splitext(basename(file))[1]))
    graphs = Dict("$graphdir/$(basename(fname))" => gnn_from_graphml(joinpath(loaddir, fname)) for fname in ProgressBar(sorted_files))
    graphs
end

function load_graphs_and_make_pairs(graphdirs::Vector{String}, csv_dir::String)
    # Load all graphs in order into a vector of GNNGraphs
    graphs = merge([load_graphs(graphdir) for graphdir in graphdirs]...)
    
    # Load CSV data
    csv_data = CSV.read(joinpath(ENV["DATA_DIR"], csv_dir, "ged.csv"), DataFrame)
    
    # Create GEDTrainPairs
    pairs = GEDTrainPair[]  # Initialize an empty array for GEDTrainPairs
    normdists = normalize_data([row[:dist] for row in eachrow(csv_data)])
    
    for (row, normdist) in ProgressBar(zip(eachrow(csv_data), normdists))
        left_index = row[:left]
        println(left_index)
        right_index = row[:right]
        println(right_index)
        dist = Float32(row[:dist])
        g1 = graphs[left_index]
        g2 = graphs[right_index]
        scaledist = Float32(dist / ((g1.num_nodes + g2.num_nodes) / 2))
        # Julia array indices start at 1, so adjust if your file names start at 0
        dists = Dict("raw" => dist, "scale" => scaledist, "norm" => normdist)
        pair = GEDTrainPair(graphs[left_index], graphs[right_index], dists)
        push!(pairs, pair)
    end
    
    return pairs
end