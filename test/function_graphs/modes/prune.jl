
using StatsBase: median
# Function to remove a subtree and redirect connections
function remove_node_and_redirect(
    genotype::FunctionGraphGenotype, 
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

        new_input_connections = FunctionGraphConnection[]
        for connection in node.input_connections
            if connection.input_node_id == to_prune_node_id
                push!(new_input_connections, FunctionGraphConnection(
                    input_node_id = bias_node_id, 
                    weight = new_weight, 
                    is_recurrent = false
                ))
            else
                push!(new_input_connections, connection)
            end
        end
        genotype.nodes[id] = FunctionGraphNode(id, node.func, new_input_connections)
    end

    # Remove the nodes in the subtree
    delete!(genotype.nodes, to_prune_node_id)
    filter!(x -> x != to_prune_node_id, genotype.hidden_node_ids)

    return genotype
end
# Prune a single node and return the updated genotype, error, and observation
function modes_prune(genotype::FunctionGraphGenotype, node_id::Int, weight::Real)
    bias_node_id = first(genotype.bias_node_ids)
    pruned_genotype = remove_node_and_redirect(genotype, node_id, bias_node_id, Float64(weight))
    pruned_genotype = minimize(pruned_genotype)
    return pruned_genotype
end