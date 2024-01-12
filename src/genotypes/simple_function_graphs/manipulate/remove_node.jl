export remove_node!

using ...Abstract 

function remove_node!(genotype::SimpleFunctionGraphGenotype, state::State)
    if length(genotype.hidden_nodes) == 0
        return 
    end
    node_to_delete_id = rand(state.rng, genotype.hidden_ids)
    filter!(node -> node.id != node_to_delete_id, genotype.nodes)
    for node in genotype.nodes
        edges_to_redirect = filter(edge -> edge.target == node_to_delete_id, node.edges)
        for edge in edges_to_redirect
            new_target = edge.is_recurrent ? 
                get_random_recurrent_edge_target(genotype, state) : 
                get_random_nonrecurrent_edge_target(genotype, node, state)
            edge.target = new_target
        end
    end
end

remove_node!(genotype::SimpleFunctionGraphGenotype, ::Mutator, state::State) = 
    remove_node!(genotype, state)