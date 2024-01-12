export mutate_node!, create_edge!

function create_edge!(
    node::Node,
    genotype::SimpleFunctionGraphGenotype, 
    mutator::Mutator, 
    state::State
)
    is_recurrent = rand(state.rng) < mutator.recurrent_edge_probability ? true : false
    target = is_recurrent ? 
        get_random_recurrent_edge_target(genotype, state) : 
        get_random_nonrecurrent_edge_target(genotype, node, state)
    weight = 0.0f0 #get_random_weight_value(mutator, state)
    edge = Edge(
        source = node.id,
        target = target,
        weight = weight,
        is_recurrent = is_recurrent
    )
    push!(node.edges, edge)
end


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
            create_edge!(node, genotype, mutator, state)
        end
    else
        # Remove edges
        n_edges_to_remove = old_function.arity - new_function.arity
        edges_to_remove = sample(state.rng, node.edges, n_edges_to_remove, replace = false)
        filter!(edge -> !(edge in edges_to_remove), node.edges)
    end
    shuffle!(state.rng, node.edges)
end

