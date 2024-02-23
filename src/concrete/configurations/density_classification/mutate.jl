export PerBitMutator, mutate!
using ....Abstract

Base.@kwdef struct PerBitMutator <: Mutator
    flip_chance::Float64 = 0.02
end

#function mutate!(mutator::PerBitMutator, genotype::BasicVectorGenotype, state::State)
#    #noise_vector = randn(rng, T, length(genotype))
#    genes = genotype.genes
#    for i in eachindex(genes)
#        if rand(state.rng) < mutator.flip_chance
#            genes[i] = rand(state.rng) < 0.5 ? 0 : 1
#        end
#    end
#end

using Random  # Ensure the Random module is used for shuffle!

function mutate!(mutator::PerBitMutator, genotype::BasicVectorGenotype, state::State)
    genes = genotype.genes
    if rand(state.rng) < 0.1
        # 10% chance to perform bit flips
        for i in eachindex(genes)
            if rand(state.rng) < mutator.flip_chance
                genes[i] = rand(state.rng) < 0.5 ? 0 : 1
            end
        end
    else
        # 90% chance to shuffle a window within the genes
        window_size = rand(1:length(genes))  # Determine the window size
        start_index = rand(1:(length(genes) - window_size + 1))  # Start index of the window
        end_index = start_index + window_size - 1  # End index of the window

        # Select the window and shuffle it
        window = genes[start_index:end_index]
        shuffle!(state.rng, window)  # Shuffle using the provided RNG for consistency

        # Place the shuffled window back
        genes[start_index:end_index] = window
    end
end
