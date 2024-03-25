module Vectors

export BasicVectorMutator, NumbersGameVectorMutator, mutate

import ....Interfaces: mutate, mutate!

using Random: AbstractRNG, randn
using StatsBase
using ....Abstract
using ...Genotypes.Vectors: BasicVectorGenotype

Base.@kwdef struct BasicVectorMutator <: Mutator
    noise_standard_deviation::Float64 = 0.1
end

function mutate(
    mutator::BasicVectorMutator, 
    rng::AbstractRNG,
    ::Counter,
    genotype::BasicVectorGenotype{T}
) where T
    noise_vector = randn(rng, T, length(genotype))
    scaled_noise_vector = noise_vector .* mutator.noise_standard_deviation
    mutated_genes = genotype.genes .+ scaled_noise_vector
    mutated_genotype = BasicVectorGenotype(mutated_genes)
    return mutated_genotype
end

export NumbersGameVectorMutator, mutate!

Base.@kwdef struct NumbersGameVectorMutator <: Mutator
    n_mutations::Int = 2
    min_mutation::Float64 = -0.1
    max_mutation::Float64 = 0.1
    mutation_granularity::Float64 = 0.01
end

function mutate!(
    mutator::NumbersGameVectorMutator, genotype::BasicVectorGenotype{T}, state::State
) where T
    indices_to_mutate = sample(1:length(genotype.genes), mutator.n_mutations; replace = false)
    for index in indices_to_mutate
        mutation_range = mutator.min_mutation:mutator.mutation_granularity:mutator.max_mutation
        genotype.genes[index] += rand(state.rng, mutation_range)
        if genotype.genes[index] < 0.0
            genotype.genes[index] = 0.0
        end
    end
end
end