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
        onehot_encoder(edata_new, ["0", "1", "01", "P"])
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
    dist::Float64
end

function load_graphs_and_make_pairs(graphdir::String, csv_file::String)
    # Load all graphs in order into a vector of GNNGraphs
    files = glob("*.graphml", graphdir)
    sorted_files = sort(files, by = file -> parse(Int, splitext(basename(file))[1]))
    
    graphs = [gnn_from_graphml(file) for file in sorted_files]
    
    # Load CSV data
    csv_data = CSV.read(csv_file, DataFrame)
    
    # Create GEDTrainPairs
    pairs = GEDTrainPair[]  # Initialize an empty array for GEDTrainPairs
    
    for row in eachrow(csv_data)
        left_index = row[:left]
        right_index = row[:right]
        dist = row[:dist]
        
        # Julia array indices start at 1, so adjust if your file names start at 0
        pair = GEDTrainPair(graphs[left_index], graphs[right_index], dist)
        push!(pairs, pair)
    end
    
    return pairs
end