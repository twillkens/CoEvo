export mutate_weight!, get_random_weight_value

get_random_weight_value(mutator::Mutator, state::State) = 
    get_random_uniform_value(mutator.weight_value_range, state)

function mutate_weight!(edge::Edge, mutator::Mutator, state::State)
    edge.weight = get_random_weight_value(mutator, state)
end

function mutate_weight!(
    genotype::FunctionGraphGenotype, mutator::Mutator, state::State
)
    edge = rand(state.rng, genotype.edges)
    mutate_weight!(edge, mutator, state)
end