using ...Genotypes.FunctionGraphs: FunctionGraphGenotype, FunctionGraphGenotypeCreator
using ...Genotypes.FunctionGraphs: FunctionGraphNode, FunctionGraphConnection, GraphFunction

function archive!(file::File, base_path::String, genotype::FunctionGraphGenotype)
    # Saving node id lists.
    file["$base_path/input_node_ids"] = genotype.input_node_ids
    file["$base_path/bias_node_ids"] = genotype.bias_node_ids
    file["$base_path/hidden_node_ids"] = genotype.hidden_node_ids
    file["$base_path/output_node_ids"] = genotype.output_node_ids
    file["$base_path/n_nodes_per_output"] = genotype.n_nodes_per_output
    
    # Ensure ordered saving of node-related data.
    ordered_node_ids = sort(collect(keys(genotype.nodes)))
    ordered_nodes = [genotype.nodes[id] for id in ordered_node_ids]
    
    file["$base_path/node_ids"] = ordered_node_ids
    file["$base_path/node_functions"] = [string(node.func) for node in ordered_nodes]
    
    #genotype_group["connection_data"] = connection_data
        # Separate fields for connection data to avoid type issues.
    connection_node_ids = Int[]
    connection_input_ids = Int[]
    connection_weights = Float64[]
    connection_is_recurrent = Bool[]

    for node in ordered_nodes
        for conn in node.input_connections
            push!(connection_node_ids, node.id)
            push!(connection_input_ids, conn.input_node_id)
            push!(connection_weights, conn.weight)
            push!(connection_is_recurrent, conn.is_recurrent)
        end
    end

    file["$base_path/connection_node_ids"] = connection_node_ids
    file["$base_path/connection_input_ids"] = connection_input_ids
    file["$base_path/connection_weights"] = connection_weights
    file["$base_path/connection_is_recurrent"] = connection_is_recurrent
end

function load(file::File, base_path::String, ::FunctionGraphGenotypeCreator,)
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