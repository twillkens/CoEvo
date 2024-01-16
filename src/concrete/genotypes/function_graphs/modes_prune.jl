export remove_node_and_redirect, substitute_node_with_bias_connection, get_prunable_genes

function remove_node_and_redirect(
    genotype::FunctionGraphGenotype, 
    to_prune_node_id::Int, 
    bias_node_id::Int, 
    new_weight::Float64,
)
    genotype = deepcopy(genotype)
    filter!(node -> node.id != to_prune_node_id, genotype.nodes)
    # Redirect connections
    for node in genotype.nodes
        for edge in node.edges
            if edge.target == to_prune_node_id
                edge.target = bias_node_id
                edge.weight = new_weight
                edge.is_recurrent = true
            end
        end
    end
    return genotype
end
# Prune a single node and return the updated genotype, error, and observation
function substitute_node_with_bias_connection(
    genotype::FunctionGraphGenotype, node_id::Int, weight::Real
)
    bias_node_id = first(genotype.bias_ids)
    pruned_genotype = remove_node_and_redirect(genotype, node_id, bias_node_id, Float64(weight))
    pruned_genotype = minimize(pruned_genotype)
    return pruned_genotype
end

function get_prunable_genes(genotype::FunctionGraphGenotype)
    gene_ids = sort(genotype.hidden_node_ids, rev = true)
    return gene_ids
end