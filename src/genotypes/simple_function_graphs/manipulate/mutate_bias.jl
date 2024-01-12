export mutate_bias!, get_random_bias_value

get_random_bias_value(mutator::Mutator, state::State) = 
    get_random_uniform_value(mutator.bias_value_range, state)


function mutate_bias!(node::Node, mutator::Mutator, state::State)
    node.bias = get_random_bias_value(mutator, state)
end

function mutate_bias!(
    genotype::SimpleFunctionGraphGenotype, mutator::Mutator, state::State
)
    node = rand(state.rng, [genotype.hidden_nodes ; genotype.output_nodes])
    mutate_bias!(node, mutator, state)
end