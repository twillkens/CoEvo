using ...Genotypes.FunctionGraphs: FunctionGraphGenotype, FunctionGraphGenotypeCreator
using ...Genotypes.FunctionGraphs: FunctionGraphNode, FunctionGraphConnection, GraphFunction

function archive!(::BasicArchiver, genotype::FunctionGraphGenotype, genotype_group::Group)
    # Saving node id lists.
    genotype_group["input_node_ids"] = genotype.input_node_ids
    genotype_group["bias_node_ids"] = genotype.bias_node_ids
    genotype_group["hidden_node_ids"] = genotype.hidden_node_ids
    genotype_group["output_node_ids"] = genotype.output_node_ids
    genotype_group["n_nodes_per_output"] = genotype.n_nodes_per_output
    
    # Ensure ordered saving of node-related data.
    ordered_node_ids = sort(collect(keys(genotype.nodes)))
    ordered_nodes = [genotype.nodes[id] for id in ordered_node_ids]
    
    genotype_group["node_ids"] = ordered_node_ids
    genotype_group["node_functions"] = [string(node.func) for node in ordered_nodes]
    
    # Collecting and saving connection-related data in a structured way.
    #connection_data = []
    #for node in ordered_nodes
    #    for conn in node.input_connections
    #        push!(connection_data, (node.id, conn.input_node_id, conn.weight, conn.is_recurrent))
    #    end
    #end
    
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

    genotype_group["connection_node_ids"] = connection_node_ids
    genotype_group["connection_input_ids"] = connection_input_ids
    genotype_group["connection_weights"] = connection_weights
    genotype_group["connection_is_recurrent"] = connection_is_recurrent
end

function load(
    archiver::BasicArchiver, ::FunctionGraphGenotypeCreator, genotype_group::Group
)
    # Load node id lists directly.
    input_node_ids = genotype_group["input_node_ids"]
    bias_node_ids = genotype_group["bias_node_ids"]
    hidden_node_ids = genotype_group["hidden_node_ids"]
    output_node_ids = genotype_group["output_node_ids"]
    n_nodes_per_output = genotype_group["n_nodes_per_output"]
    
    # Load node-related data.
    node_ids = genotype_group["node_ids"]
    node_functions = genotype_group["node_functions"]
    
    # Initialize an empty nodes dictionary.
    nodes = Dict{Int, FunctionGraphNode}()
    for (id, func) in zip(node_ids, node_functions)
        nodes[id] = FunctionGraphNode(id, Symbol(func), FunctionGraphConnection[])
    end
    
    # # Load connection data and establish connections.
    # connection_data = genotype_group["connection_data"]
    # for (node_id, input_id, weight, is_recurrent) in connection_data
    #     connection = FunctionGraphConnection(input_id, weight, is_recurrent)
    #     push!(nodes[node_id].input_connections, connection)
    # end
    # Load connection data from separate fields.
    connection_node_ids = genotype_group["connection_node_ids"]
    connection_input_ids = genotype_group["connection_input_ids"]
    connection_weights = genotype_group["connection_weights"]
    connection_is_recurrent = genotype_group["connection_is_recurrent"]

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