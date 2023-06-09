using LightXML, GraphNeuralNetworks, Flux
include("scratch.jl")

using Flux: onehot
using LightXML

function map_to_integers(data, categories)
    return map(d -> findfirst(==(d), categories), data)
end

function onehot_encoder(data, categories)
    integer_data = map_to_integers(data, categories)
    return hcat(map(d -> onehot(d, 1:length(categories)), integer_data)...)
end

function graphml_to_data(file_path)
    # Read the XML document
    xdoc = parse_file(file_path)
    xroot = root(xdoc)

    # Extract nodes and edges
    nodes = get_elements_by_tagname(xroot, "node")
    edges = get_elements_by_tagname(xroot, "edge")

    # Define categories for one-hot encoding
    node_categories = ["0", "1", "P", "1_start", "0_start"]
    edge_categories = ["0", "1", "01", "P"]

    # Extract node labels and encode them
    node_labels = [content(find_element(node, "data")) for node in nodes]
    ndata = onehot_encoder(node_labels, node_categories)

    # Extract edge labels and encode them
    edge_labels = [content(find_element(edge, "data")) for edge in edges]
    edata = onehot_encoder(edge_labels, edge_categories)

    # Create adjacency list from edges
    adjacency_list = [String[] for _ in nodes]  # Initialize empty list of vectors
    for edge in edges
        source = findfirst(==(attribute(edge, "source")), [attribute(node, "id") for node in nodes])
        target = findfirst(==(attribute(edge, "target")), [attribute(node, "id") for node in nodes])
        push!(adjacency_list[source], attribute(edge, "target"))
        push!(adjacency_list[target], attribute(edge, "source"))  # Since the graph is undirected
    end

    return adjacency_list, ndata, edata
end

# using EzXML

function parseGraphML(file_path)
    doc = readxml(file_path)
    
    # Prepare dictionaries
    node_color = Dict()
    edge_weight = Dict()
    
    # Parse the keys
    for key in findall("//key", doc)
        id = attribute(key, "id")
        for_attr = attribute(key, "for")
        attr_name = attribute(key, "attr.name")

        # Find the data associated with the keys
        for data in findall("//$(for_attr)/data[@key='$(id)']", doc)
            value = nodecontent(data)
            element_id = attribute(parent(data), "id")
            
            if for_attr == "node" && attr_name == "color"
                node_color[element_id] = value
            elseif for_attr == "edge" && attr_name == "weight"
                edge_weight[tuple(split(element_id, "_")...)] = parse(Float64, value)
            end
        end
    end

    # Prepare the adjacency list
    adjacency_list = Dict()
    for edge in findall("//edge", doc)
        source = attribute(edge, "source")
        target = attribute(edge, "target")
        
        if !haskey(adjacency_list, source)
            adjacency_list[source] = []
        end
        push!(adjacency_list[source], target)
    end
    
    # Convert adjacency list to a vector of vectors
    adjacency_list_vec = [v for v in values(adjacency_list)]

    return adjacency_list_vec, node_color, edge_weight
end

using LightXML

function parse_graphml(file)
    xdoc = parse_file(file)
    xroot = root(xdoc)

    # Create adjacency list
    adj_list = Dict{String, Vector{String}}()

    # Create node_color and edge_weight dictionary
    node_color = Dict{String, String}()
    edge_weight = Dict{Tuple{String, String}, Float64}()

    # Retrieve keys (for node color and edge weight)
    keys_node = find_elements(xroot, "//key[@for='node']")
    keys_edge = find_elements(xroot, "//key[@for='edge']")
    key_node_color = nothing
    key_edge_weight = nothing

    for key in keys_node
        attr_name = attribute(key, "attr.name")
        if attr_name == "color"
            key_node_color = attribute(key, "id")
        end
    end

    for key in keys_edge
        attr_name = attribute(key, "attr.name")
        if attr_name == "weight"
            key_edge_weight = attribute(key, "id")
        end
    end

    # Parse nodes and edges
    for child in child_elements(xroot)
        if name(child) == "node"
            node_id = attribute(child, "id")
            adj_list[node_id] = []
            for data in child_elements(child)
                if attribute(data, "key") == key_node_color
                    node_color[node_id] = content(data)
                end
            end
        elseif name(child) == "edge"
            source_id = attribute(child, "source")
            target_id = attribute(child, "target")
            push!(adj_list[source_id], target_id)
            for data in child_elements(child)
                if attribute(data, "key") == key_edge_weight
                    edge_weight[(source_id, target_id)] = parse(Float64, content(data))
                end
            end
        end
    end
    return adj_list, node_color, edge_weight
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

xdoc = parse_file("test.graphml")
xroot = root(xdoc)
graph = first(filter(e -> name(e) == "graph", get_elements(xroot)))
nodes = filter(e -> name(e) == "node", get_elements(graph))
edges = filter(e -> name(e) == "edge", get_elements(graph))
node_ids = map(e -> attribute(e, "id"), nodes)
adj = Dict([id => String[] for id in node_ids])
for edge in edges
    source = attribute(edge, "source")
    target = attribute(edge, "target")
    push!(adj[source], target)
    push!(adj[target], source)
end


println(keys)