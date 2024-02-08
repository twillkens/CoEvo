export mutate, mutate!

using ..Abstract

function mutate!(mutator::Mutator, individual::Individual, reproducer::Reproducer, state::State)
    mutator = typeof(mutator)
    individual = typeof(individual)
    reproducer = typeof(reproducer)
    state = typeof(state)
    error("mutate! not implemented for $mutator, $individual, $reproducer, $state")
end

function mutate!(mutator::Mutator, genotype::Genotype, state::State)
    mutator = typeof(mutator)
    genotype = typeof(genotype)
    state = typeof(state)
    error("mutate! not implemented for $mutator, $genotype, $state")
end

function mutate(mutator::Mutator, individual::Individual, reproducer::Reproducer, state::State)
    new_individual = deepcopy(individual)
    mutate!(mutator, new_individual, reproducer, state)
    return new_individual
end

function mutate(mutator::Mutator, genotype::Genotype, state::State)
    new_genotype = deepcopy(genotype)
    mutate!(mutator, new_genotype, state)
    return new_genotype
end

