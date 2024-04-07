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

export PerBitMutator, mutate!
using Distributions

Base.@kwdef struct PerBitMutator <: Mutator
    flip_chance::Float64 = 0.01
    flip_window::Int = 5
    use_symmetry::Bool = false
end

function get_exponential_window_size(max_size::Int, rng::AbstractRNG)
    # Define the scale of the distribution to better fit the desired window size range
    scale_factor = max_size / 5  # Adjust the scale factor to control distribution spread
    
    # Create an exponential distribution with mean = scale_factor
    exp_dist = Exponential(scale_factor)
    
    while true
        # Generate a window size from the exponential distribution
        window_size = round(Int, rand(rng, exp_dist))
        
        # If the window size is within the valid range, return it
        if 1 <= window_size <= max_size
            return window_size
        end
        # Otherwise, regenerate the window size
    end
end

function mutate!(mutator::PerBitMutator, genotype::BasicVectorGenotype, state::State)
    genes = genotype.genes
    if false
    #if mutator.use_symmetry
        x = rand()
        if x < 0.1
            genes = collect(reverse(genes))
        elseif x < 0.2
            genes = [1 - gene for gene in genes]
        elseif x < 0.3
            genes = [1 - gene for gene in collect(reverse(genes))]
        else
            flip_chance = mutator.flip_chance * get_exponential_window_size(mutator.flip_window, state.rng)
            #flip_chance = mutator.flip_chance
            for i in eachindex(genes)
                if rand(state.rng) < flip_chance
                    genes[i] = 1 - genes[i]
                end
            end
        end
    else
        #flip_chance = mutator.flip_chance * get_exponential_window_size(mutator.flip_window, state.rng)
        flip_chance = mutator.flip_chance
        for i in eachindex(genes)
            if rand(state.rng) < flip_chance
                genes[i] = 1 - genes[i]
            end
        end
    end
end

end
