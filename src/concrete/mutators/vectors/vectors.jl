module Vectors

export BasicVectorMutator

import ....Interfaces: mutate

using Random: AbstractRNG, randn
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

end