using ...Genotypes.FunctionGraphs: FunctionGraphGenotype
using ...Genotypes.FunctionGraphs: FunctionGraphNode, FunctionGraphConnection, GraphFunction

function save_genotype!(::BasicArchiver, geno_group::Group, genotype::FunctionGraphGenotype)
    # Saving node id lists.
    geno_group["input_node_ids"] = genotype.input_node_ids
    geno_group["bias_node_ids"] = genotype.bias_node_ids
    geno_group["hidden_node_ids"] = genotype.hidden_node_ids
    geno_group["output_node_ids"] = genotype.output_node_ids
    geno_group["n_nodes_per_output"] = genotype.n_nodes_per_output
    
    # Ensure ordered saving of node-related data.
    ordered_node_ids = sort(collect(keys(genotype.nodes)))
    ordered_nodes = [genotype.nodes[id] for id in ordered_node_ids]
    
    geno_group["node_ids"] = ordered_node_ids
    geno_group["node_functions"] = [node.func for node in ordered_nodes]
    
    # Collecting and saving connection-related data in a structured way.
    connection_data = []
    for node in ordered_nodes
        for conn in node.input_connections
            push!(connection_data, (node.id, conn.input_node_id, conn.weight, conn.is_recurrent))
        end
    end
    
    geno_group["connection_data"] = connection_data
end
