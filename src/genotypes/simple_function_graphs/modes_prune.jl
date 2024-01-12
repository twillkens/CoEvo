
function remove_node_and_redirect(
    genotype::SimpleFunctionGraphGenotype, 
    to_prune_node_id::Int, 
    bias_node_id::Int, 
    new_weight::Float64,
)
    genotype = deepcopy(genotype)
    # Redirect connections
    for (id, node) in genotype.nodes
        if id == to_prune_node_id
            continue
        end

        new_edges = Edge[]
        for connection in node.edges
            if connection.target == to_prune_node_id
                push!(new_edges, Edge(
                    target = bias_node_id, 
                    weight = new_weight, 
                    is_recurrent = true
                ))
            else
                push!(new_edges, connection)
            end
        end
        genotype.nodes[id] = Node(id, node.func, new_edges)
    end

    # Remove the nodes in the subtree
    delete!(genotype.nodes, to_prune_node_id)
    filter!(x -> x != to_prune_node_id, genotype.hidden_node_ids)

    return genotype
end
# Prune a single node and return the updated genotype, error, and observation
function substitute_node_with_bias_connection(
    genotype::SimpleFunctionGraphGenotype, node_id::Int, weight::Real
)
    bias_node_id = first(genotype.bias_node_ids)
    pruned_genotype = remove_node_and_redirect(genotype, node_id, bias_node_id, Float64(weight))
    pruned_genotype = minimize(pruned_genotype)
    return pruned_genotype
end

function get_prunable_genes(genotype::SimpleFunctionGraphGenotype)
    gene_ids = sort(genotype.hidden_node_ids, rev = true)
    return gene_ids
end