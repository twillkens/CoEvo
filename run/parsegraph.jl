using LightXML, GraphNeuralNetworks, Flux
using Glob
using Flux: onehotbatch
using LightXML
using CSV, DataFrames

# Gets all child elements of an XMLElement
function get_elements(xroot::XMLElement)
    es = XMLElement[]
    for c in child_nodes(xroot)  # c is an instance of XMLNode
        if is_elementnode(c)
            e = XMLElement(c)  # this makes an XMLElement instance
            push!(es, e)
        end
    end
    es
end

# Parses and converts an XMLDocument into an FSMPrimeGeno
function FSMPrimeGeno(xdoc::XMLDocument)
    xroot = root(xdoc)
    graph = first(filter(e -> name(e) == "graph", get_elements(xroot)))
    nodes = filter(e -> name(e) == "node", get_elements(graph))
    ones = Set{String}()
    zeros = Set{String}()
    primes = Set{String}()
    start = ""
    for node in nodes
        id = attribute(node, "id")
        data = first(filter(e -> name(e) == "data", get_elements(node)))
        label = content(first(child_nodes(data)))
        if label == "1"
            push!(ones, id)
        elseif label == "0"
            push!(zeros, id)
        elseif label == "P"
            push!(primes, id)
        end
        if label == "1_start" || label == "0_start"
            start = id
        end
    end
    edges = filter(e -> name(e) == "edge", get_elements(graph))
    links = Dict{Tuple{String, String}, String}()
    for edge in edges
        source = attribute(edge, "source")
        target = attribute(edge, "target")
        data = first(filter(e -> name(e) == "data", get_elements(edge)))
        label = content(first(child_nodes(data)))
        push!(links, ((source, label) => target))
    end
    FSMPrimeGeno(start, ones, zeros, primes, links)
end

# Loads the xml file at filepath and returns a FSMPrimeGeno
function FSMPrimeGeno(filepath::String = "1.graphml")
    xdoc = LightXML.parse_file(filepath)
    geno = FSMPrimeGeno(xdoc)
    free(xdoc)
    geno
end

# Converts a FSMPrimeGeno to a GNNGraph
# This requires the node labels of the prime geno to be parsable as integers
# The number of edges in the GNNGraph will be twice the number of edges in the FSMPrimeGeno
# as we add edges in both directions
# The number of nodes in the GNNGraph will be twice the number of nodes in the FSMPrimeGeno
# There are five node labels: 0, 1, 1_start, 0_start, P
# There are seven edge labels: 0, 1, 01, P, 0P, 1P, 01P 
function GraphNeuralNetworks.GNNGraph(
    prime_geno::FSMPrimeGeno; 
    node_label_vec = ["0", "0_start", "1", "1_start", "P"], 
    edge_label_vec = ["0", "1", "01", "P", "0P", "1P", "01P"]
)
    all_nodes = union(prime_geno.ones, prime_geno.zeros)
    num_nodes = length(all_nodes)
    # We obtain node ids by parsing and sorting the nodes and then mapping them to integers
    sorted_nodes = sort(parse(Int, node) for node in all_nodes)
    node_id_map = Dict(string(node) => i for (i, node) in enumerate(sorted_nodes))
    # We add the "prime nodes" to the node id map. If 50 nodes, node 1 has prime node 51, etc.
    merge!(node_id_map, Dict(node * "P" => place + num_nodes for (node, place) in node_id_map))
    # Node labels for nonprime nodes are 0, 1, or 1_start, 0_start.
    # We merge two sorted dicts to get them in the correct order before adding the correct 
    # start label
    node_labels = merge(
        SortedDict([node_id_map[node] => "0" for node in prime_geno.zeros]),
        SortedDict([node_id_map[node] => "1" for node in prime_geno.ones]),
    )
    start_label = prime_geno.start in prime_geno.ones ? "1_start" : "0_start"
    node_labels[node_id_map[prime_geno.start]] = start_label
    # Final labels are the node label values, which are in sorted order
    node_labels = collect(values(node_labels))
    # We then add the prime nodes to the node labels; we know they are equal in number and all P
    [push!(node_labels, "P") for _ in eachindex(node_labels)]
    # We then create the edge labels as well as the ad
    sources, targets, edge_labels = Int[], Int[], String[]
    for ((source, label), target) in prime_geno.links
        push!(sources, node_id_map[source])
        push!(targets, node_id_map[target])
        push!(edge_labels, label)
    end

    # We then add the reverse edges
    undirected_sources = vcat(sources, targets)
    undirected_targets = vcat(targets, sources)
    undirected_edge_labels = vcat(edge_labels, edge_labels)
    # We then create the node and edge data
    ndata = Matrix{Float32}(onehotbatch(node_labels, node_label_vec))
    edata = Matrix{Float32}(onehotbatch(undirected_edge_labels, edge_label_vec))
    GNNGraph(undirected_sources, undirected_targets; ndata = ndata, edata = edata)
end


# Given a matrix, returns a vector of integers corresponding to the index of the 1 in each column
function get_onehot_indices(mat::Matrix{Float32})
    return [findfirst(==(1), mat[:, col]) for col in 1:size(mat, 2)]
end

# Converts a GNNGraph to a FSMPrimeGeno
function FSMPrimeGeno(
    graph::GNNGraph; 
    node_label_vec = ["0", "0_start", "1", "1_start", "P"], 
    edge_label_vec = ["0", "1", "01", "P", "0P", "1P", "01P"],
)
    # We first get the node labels
    node_label_idxs = get_onehot_indices(graph.ndata.x)
    ones, zeros, primes = Set{String}(), Set{String}(), Set{String}()
    start = ""
    # We parse the node labels
    for (i, label_idx) in enumerate(node_label_idxs)
        label = node_label_vec[label_idx]
        if label == "0"
            push!(zeros, string(i))
        elseif label == "0_start"
            push!(zeros, string(i))
            start = string(i)
        elseif label == "1"
            push!(ones, string(i))
        elseif label == "1_start"
            push!(ones, string(i))
            start = string(i)
        elseif label == "P"
            push!(primes, string(i - graph.num_nodes ÷ 2) * "P")
        end
    end
    # We then get the edge labels
    edge_label_idxs = get_onehot_indices(graph.edata.e)
    sources, targets, _ = graph.graph
    # We will only extract the edges running from the nonprime nodes to the prime nodes
    half_length = length(sources) ÷ 2
    # We know that all edges in the first half of the graph are nonprime to prime
    # We can then get the id of the original target node by subtracting half the number of nodes
    links = Dict(
        (string(source), string(edge_label_vec[label_idx])) => 
        string(target - graph.num_nodes ÷ 2) * "P" 
        for (source, label_idx, target) in 
            zip(sources[1:half_length], edge_label_idxs[1:half_length], targets[1:half_length])
    )
    FSMPrimeGeno(start, ones, zeros, primes, links)
end

struct GEDTrainPair
    g1::GNNGraph
    g2::GNNGraph
    dists::Dict{String, Float32}
end

# Load all graphs in a directory into a dictionary of filenames => GNNGraphs
function load_gnn_graphs(graphdir::String)
    files = glob("*.graphml", graphdir)
    Dict(
        "$graphdir/$(basename(fname))" => 
        GraphNeuralNetworks.GNNGraph(
            FSMPrimeGeno(joinpath(loaddir, fname)) for fname in ProgressBar(files)
        )
    )
end

# Load all graphs from multiple directories into a dictionary of filenames => GNNGraphs
function load_gnn_graphs(graphdirs::Vector{String})
    merge([load_graphs(graphdir) for graphdir in graphdirs]...)
end

function load_ged_train_pairs(graphdirs::Vector{String}, csv_path::String)
    # Load all graphs in order into a vector of GNNGraphs
    graphs = merge([load_gnn_graphs(graphdir) for graphdir in graphdirs]...)
    # Load CSV data
    csv_data = CSV.read(csv_path, DataFrame)
    # Create GEDTrainPairs
    pairs = GEDTrainPair[]  # Initialize an empty array for GEDTrainPairs
    for row in ProgressBar(eachrow(csv_data))
        left_index = row[:left]
        right_index = row[:right]
        g1 = graphs[left_index]
        g2 = graphs[right_index]
        # Following UGraphEmb paper
        dists = Dict(
            "raw_lower" => Float32(row[:lower]), 
            "raw_upper" => Float32(row[:upper]), 
            "scaled_lower" => Float32(row[:lower] / ((g1.num_nodes + g2.num_nodes) / 2)), 
            "scaled_upper" => Float32(row[:upper] / ((g1.num_nodes + g2.num_nodes) / 2)),
        )
        pair = GEDTrainPair(g1, g2, dists)
        push!(pairs, pair)
    end
    return pairs
end