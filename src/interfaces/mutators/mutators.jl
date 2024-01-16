export mutate, mutate!

using ..Abstract

function mutate!(mutator::Mutator, individual::Individual, state::State)
    mutator = typeof(mutator)
    individual = typeof(individual)
    state = typeof(state)
    error("mutate! not implemented for $mutator, $individual, $state")
end

function mutate!(mutator::Mutator, genotype::Genotype, state::State)
    mutator = typeof(mutator)
    genotype = typeof(genotype)
    state = typeof(state)
    error("mutate! not implemented for $mutator, $genotype, $state")
end

function mutate(mutator::Mutator, individual::Individual, state::State)
    new_individual = deepcopy(individual)
    mutate!(mutator, new_individual, state)
    return new_individual
end

function mutate(mutator::Mutator, genotype::Genotype, state::State)
    new_genotype = deepcopy(genotype)
    mutate!(mutator, new_genotype, state)
    return new_genotype
end

