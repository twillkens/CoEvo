export PerBitMutator, mutate!
using ....Abstract

Base.@kwdef struct PerBitMutator <: Mutator
    flip_chance::Float64 = 0.02
end

function mutate!(mutator::PerBitMutator, genotype::BasicVectorGenotype, state::State)
    #noise_vector = randn(rng, T, length(genotype))
    genes = genotype.genes
    for i in eachindex(genes)
        if rand(state.rng) < mutator.flip_chance
            genes[i] = rand(state.rng) < 0.5 ? 0 : 1
        end
    end
end