
using HDF5: h5open, File, read

import ...Genotypes: load_genotype

function load_genotype(file::File, base_path::String, ::FunctionGraphGenotypeCreator,)
    # Load node id lists directly.
    input_node_ids     = read(file["$base_path/input_node_ids"])
    bias_node_ids      = read(file["$base_path/bias_node_ids"])
    hidden_node_ids    = read(file["$base_path/hidden_node_ids"])
    output_node_ids    = read(file["$base_path/output_node_ids"])
    n_nodes_per_output = read(file["$base_path/n_nodes_per_output"])
    
    # Load node-related data.
    node_ids       = read(file["$base_path/node_ids"])
    node_functions = read(file["$base_path/node_functions"])
    
    # Initialize an empty nodes dictionary.
    nodes = Dict{Int, FunctionGraphNode}()
    for (id, func) in zip(node_ids, node_functions)
        nodes[id] = FunctionGraphNode(id, Symbol(func), FunctionGraphConnection[])
    end
    
    # Load connection data from separate fields.
    connection_node_ids     = read(file["$base_path/connection_node_ids"])
    connection_input_ids    = read(file["$base_path/connection_input_ids"])
    connection_weights      = read(file["$base_path/connection_weights"])
    connection_is_recurrent = read(file["$base_path/connection_is_recurrent"])

    for i in eachindex(connection_node_ids)
        connection = FunctionGraphConnection(
            connection_input_ids[i], 
            connection_weights[i], 
            connection_is_recurrent[i]
        )
        push!(nodes[connection_node_ids[i]].input_connections, connection)
    end
    
    # Construct and return the FunctionGraphGenotype.
    genotype = FunctionGraphGenotype(
        input_node_ids=input_node_ids,
        bias_node_ids=bias_node_ids,
        hidden_node_ids=hidden_node_ids,
        output_node_ids=output_node_ids,
        nodes=nodes,
        n_nodes_per_output=n_nodes_per_output
    )
    return genotype
end