module Vectors

export BasicVectorMutator

import ..Mutators: mutate

using Random: AbstractRNG, randn
using ...Counters: Counter
using ...Genotypes.Vectors: BasicVectorGenotype
using ..Mutators: Mutator

Base.@kwdef struct BasicVectorMutator <: Mutator
    noise_standard_deviation::Float64 = 0.1
end

function mutate(
    mutator::BasicVectorMutator, 
    random_number_generator::AbstractRNG,
    ::Counter,
    genotype::BasicVectorGenotype{T}
) where T
    noise_vector = randn(random_number_generator, T, length(genotype))
    scaled_noise_vector = noise_vector .* mutator.noise_standard_deviation
    mutated_genes = genotype.genes .+ scaled_noise_vector
    mutated_genotype = BasicVectorGenotype(mutated_genes)
    return mutated_genotype
end

end