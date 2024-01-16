import ....Interfaces: convert_to_dict, create_from_dict
using HDF5: h5open, File, read
using ....Abstract

function convert_to_dict(genotype::FunctionGraphGenotype)
    node_data = Dict()
    for node in genotype.nodes
        # Store each node's details in a nested dictionary.
        node_data[node.id] = Dict(
            "ID" => node.id,
            "FUNC" => FUNCTION_TO_UINT_MAP[node.func],
            "BIAS" => node.bias,
            "EDGES" => Dict(
                index => Dict(
                    "SOURCE" => edge.source,
                    "TARGET" => edge.target,
                    "WEIGHT" => edge.weight,
                    "RECURRENT" => edge.is_recurrent
                ) 
                for (index, edge) in enumerate(node.edges)
            )
        )
    end
    return node_data
end

function create_from_dict(::FunctionGraphGenotypeCreator, dict::Dict, ::State)
    # Initialize an empty vector for nodes
    nodes = Vector{Node}()
    #println("dict_in_genotype = ", dict)

    for (_, node_data) in dict
        # Retrieve the node details
        id = node_data["ID"]
        func = UINT_TO_FUNCTION_MAP[node_data["FUNC"]]  # Assuming UINT_TO_FUNCTION_MAP is defined to map back to the function
        bias = node_data["BIAS"]
        if !haskey(node_data, "EDGES")
            edges = Edge[]
        else
            edges = [
                Edge(
                    edge_data["SOURCE"], 
                    edge_data["TARGET"], 
                    edge_data["WEIGHT"], 
                    edge_data["RECURRENT"]) 
                for (_, edge_data) in node_data["EDGES"]
            ]
        end

        # Create a Node and add it to the nodes vector
        push!(nodes, Node(id, func, bias, edges))
    end

    # Create and return the FunctionGraphGenotype
    genotype = FunctionGraphGenotype(nodes)
    sort!(genotype.nodes, by = node -> node.id)
    return genotype
end
