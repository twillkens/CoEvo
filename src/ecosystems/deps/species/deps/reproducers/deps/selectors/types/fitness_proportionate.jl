module FitnessProportionate

export FitnessProportionateSelector

using Random: AbstractRNG
using DataStructures: OrderedDict

using ....Individuals.Abstract: Individual
using ....Species.Evaluators.Abstract: Evaluation
using ..Abstract: Selector

import ..Interfaces: select

"""
    FitnessProportionateSelector

Represents a selection strategy that chooses individuals based on their relative fitness scores.
Each individual is assigned a probability proportional to its fitness, and individuals are selected
with replacement according to these probabilities.

# Fields
- `n_parents::Int`: The number of parents to select from the population.
"""
Base.@kwdef struct FitnessProportionateSelector <: Selector
    n_parents::Int
end

"""
    roulette(rng::AbstractRNG, μ::Int, fits::Vector{<:Real})

Implements the roulette wheel algorithm for fitness-proportionate selection.

# Arguments
- `rng::AbstractRNG`: A random number generator.
- `μ::Int`: Number of selections to make.
- `fits::Vector{<:Real}`: A vector of fitness values corresponding to each individual in the population.

# Returns
- `Array{Int}`: Indices of selected individuals.
"""
function roulette(rng::AbstractRNG, μ::Int, fits::Vector{<:Real})
    absolute_fitness = abs.(fits)
    probs = absolute_fitness./sum(absolute_fitness)
    cumulative_probs = cumsum(probs)
    selected = Array{Int}(undef, μ)
    for i in 1:μ
        j = 1
        r = rand(rng)
        while cumulative_probs[j] < r
            j += 1
        end
        selected[i] = j
    end
    return selected
end

"""
    (selector::FitnessProportionateSelector)(rng::AbstractRNG, new_pop_evals::OrderedDict{<:Individual, <:Evaluation})

Selects `n_parents` from the population using the fitness-proportionate selection strategy.

# Arguments
- `rng::AbstractRNG`: A random number generator.
- `new_pop_evals::OrderedDict{<:Individual, <:Evaluation}`: An ordered dictionary of the population's 
                                                           individuals and their evaluations.

# Returns
- `Array{Individual}`: A list of selected parent individuals.
"""
function select(
    selector::FitnessProportionateSelector,
    rng::AbstractRNG, 
    new_pop_evals::OrderedDict{<:Individual, <:Evaluation}
)
    fitnesses = [eval.fitness for eval in values(new_pop_evals)]
    parent_indices = roulette(rng, selector.n_parents, fitnesses)
    parents = collect(keys(new_pop_evals))[parent_indices]
    return parents  
end

end