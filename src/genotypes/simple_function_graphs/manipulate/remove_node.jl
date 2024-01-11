export remove_node!

using ...Abstract 

function remove_node!(genotype::SimpleFunctionGraphGenotype, mutator::Mutator, state::State)
    if length(genotype.hidden_ids) == 0
        return 
    end
    node_to_delete_id = rand(state.rng, genotype.hidden_ids)
    filter!(node -> node.id != node_to_delete_id, genotype.nodes)
    for node in genotype.nodes
        for (index, edge) in enumerate(node.edges)
            if edge.target == node_to_delete_id
                new_edge = create_edge(genotype, node, mutator, state)
                if new_edge.target == node.id && !new_edge.is_recurrent
                    println("genotype = ", genotype)
                    println("edge = ", edge)
                    throw(ErrorException("REMOVE_NODE edge to self is non-recurrent"))
                end
                node.edges[index] = new_edge
            end
        end
    end
end