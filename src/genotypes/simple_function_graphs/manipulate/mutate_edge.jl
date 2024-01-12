export mutate_edge!

using ...Abstract 
using ...Abstract.States


function mutate_edge!(genotype::SimpleFunctionGraphGenotype, mutator::Mutator, state::State)
    edge = rand(state.rng, genotype.edges)
    is_recurrent = rand(state.rng) < mutator.recurrent_edge_probability ? true : false
    source_node = first(filter(node -> node.id == edge.source, genotype.nodes))
    new_target = is_recurrent ? 
        get_random_recurrent_edge_target(genotype, state) : 
        get_random_nonrecurrent_edge_target(genotype, source_node, state)
    edge.is_recurrent = is_recurrent
    edge.target = new_target
end
