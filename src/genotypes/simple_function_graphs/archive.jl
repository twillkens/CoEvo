
using HDF5: h5open, File, read

import ...Genotypes: load_genotype

function convert_to_dictionary(genotype::SimpleFunctionGraphGenotype)
    node_data = Dict()
    for node in genotype.nodes
        # Store each node's details in a nested dictionary.
        node_data[node.id] = Dict(
            "func" => string(node.func),
            "edges" => Dict(
                index => Dict(
                    "target" => edge.target,
                    "weight" => edge.weight,
                    "is_recurrent" => edge.is_recurrent
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

function archive!(file::File, base_path::String, genotype::SimpleFunctionGraphGenotype)
    dict_genotype = convert_to_dictionary(genotype)
    archive!(file, base_path, dict_genotype)
end

function load(file::File, base_path::String, genotype_creator::SimpleFunctionGraphGenotypeCreator)
    # Load the node data
    node_data = Dict()
    node_base_paths = file["$base_path"]

    for node_id in parse.(Int, keys(node_base_paths))
        node_path = "$base_path/$node_id"

        # Load the function and input connections for each node
        func = Symbol(file["$node_path/func"])
        edges = Vector{Edge}()

        connection_data = file["$node_path/edges"]
        connection_indices = sort(Int.(keys(connection_data)))
        for conn_index in connection_indices
            conn_path = "$node_path/edges/$conn_index"
            target = file["$conn_path/target"]
            weight = file["$conn_path/weight"]
            is_recurrent = file["$conn_path/is_recurrent"]

            # Create and add the connection to the list
            conn = Edge(target, weight, is_recurrent)
            push!(edges, conn)
        end

        # Create the node and add it to the node data
        node = Node(node_id, func, edges)
        node_data[node_id] = node
    end

    # Use the genotype_creator to create the genotype
    return genotype_creator(node_data)
end
