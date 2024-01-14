
using HDF5: h5open, File, read

import ....Interfaces: load_genotype

function convert_to_dictionary(genotype::FunctionGraphGenotype)
    node_data = Dict()
    for node in genotype.nodes
        # Store each node's details in a nested dictionary.
        node_data[node.id] = Dict(
            "F" => FUNCTION_TO_UINT_MAP[node.func],
            "B" => node.bias,
            "E" => Dict(
                index => Dict(
                    "S" => node.source,
                    "T" => edge.target,
                    "W" => edge.weight,
                    "R" => edge.is_recurrent
                ) 
                for (index, edge) in enumerate(node.edges)
            )
        )
    end
    return node_data
end

function archive!(file::File, base_path::String, data::Dict, path_prefix::String = "")
    for (key, value) in data
        current_path = path_prefix == "" ? "$base_path/$key" : "$path_prefix/$key"
        
        if value isa Dict
            # Recursive call for nested dictionaries
            archive!(file, base_path, value, current_path)
        else
            # Store the value directly
            file[current_path] = value
        end
    end
end

function archive!(file::File, base_path::String, genotype::FunctionGraphGenotype)
    dict_genotype = convert_to_dictionary(genotype)
    archive!(file, base_path, dict_genotype)
end

function load(file::File, base_path::String, ::FunctionGraphGenotypeCreator)
    # Load the node data
    nodes = Node[]
    node_base_paths = file["$base_path"]

    for node_id in parse.(Int, keys(node_base_paths))
        node_path = "$base_path/$node_id"

        # Load the function and input connections for each node
        func = UINT_TO_FUNCTION_MAP[file["$node_path/F"]]
        bias = file["$node_path/B"]
        edges = Vector{Edge}()

        connection_data = file["$node_path/E"]
        connection_indices = sort(Int.(keys(connection_data)))
        for conn_index in connection_indices
            conn_path = "$node_path/E/$conn_index"
            source = file["$conn_path/S"]
            target = file["$conn_path/T"]
            weight = file["$conn_path/W"]
            is_recurrent = file["$conn_path/R"]

            # Create and add the connection to the list
            conn = Edge(target, weight, is_recurrent)
            push!(edges, conn)
        end

        # Create the node and add it to the node data
        node = Node(node_id, func, bias, edges)
        push!(nodes, node)
    end

    genotype = FunctionGraphGenotype(nodes)
    return genotype
end
