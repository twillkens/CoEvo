export mutate_node!

function mutate_node!(genotype::SimpleFunctionGraphGenotype, mutator::Mutator, state::State)
    if length(genotype.hidden_nodes) == 0
        return
    end
    node = rand(state.rng, genotype.hidden_nodes)
    old_function = FUNCTION_MAP[node.func]
    new_function = FUNCTION_MAP[rand(state.rng, mutator.function_set)]
    node.func = new_function.name
    if old_function.arity < new_function.arity
        n_new_edges = new_function.arity - old_function.arity
        for _ in 1:n_new_edges
            edge = create_edge(genotype, node, mutator, state)
            push!(node.edges, edge)
        end
    else
        # Remove edges
        n_edges_to_remove = old_function.arity - new_function.arity
        edges_to_remove = sample(state.rng, node.edges, n_edges_to_remove, replace = false)
        filter!(edge -> !(edge in edges_to_remove), node.edges)
    end
    shuffle!(state.rng, node.edges)
    if length(node.edges) != new_function.arity
        println("node = $node")
        println("old_function = $old_function")
        println("new_function = $new_function")
        throw(ErrorException("Incorrect number of edges"))
    end
end

