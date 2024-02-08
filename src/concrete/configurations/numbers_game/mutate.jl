export NumbersGameVectorMutator, mutate!

Base.@kwdef struct NumbersGameVectorMutator <: Mutator
    noise_standard_deviation::Float64 = 0.1
end

function mutate!(
    ::NumbersGameVectorMutator, genotype::BasicVectorGenotype{T}, state::State
) where T
    #noise_vector = randn(rng, T, length(genotype))
    indices_to_mutate = sample(1:length(genotype.genes), 2; replace = false)
    for index in indices_to_mutate
        genotype.genes[index] += rand(state.rng, -0.15:0.01:0.1)
        if genotype.genes[index] < 0.0
            genotype.genes[index] = 0.0
        end
    end
end