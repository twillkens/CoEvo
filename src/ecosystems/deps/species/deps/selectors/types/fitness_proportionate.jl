module FitnessProportionate

export FitnessProportionateSelector

using Random: AbstractRNG
using DataStructures: OrderedDict

using ...Selectors.Abstract: Selector

import ...Selectors.Interfaces: select
using ....Species.Individuals: Individual
using ....Species.Evaluators.Types.ScalarFitness: ScalarFitnessEvaluation


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
function roulette(rng::AbstractRNG, n_parents::Int, fitnesses::Vector{<:Real})
    if any(fitnesses .<= 0)
        throw(ArgumentError("Fitness values must be strictly positive for FitnessProportionateSelector."))
    end
    probabilities = fitnesses ./ sum(fitnesses)
    cumulative_probabilities = cumsum(probabilities)
    parents = Array{Int}(undef, n_parents)
    spins = rand(rng, n_parents)
    for (n_parent, spin) in enumerate(spins)
        candidate_index = 1
        while cumulative_probabilities[candidate_index] < spin
            candidate_index += 1
        end
        parents[n_parent] = candidate_index
    end
    return parents
end

function select(
    selector::FitnessProportionateSelector,
    rng::AbstractRNG, 
    new_population::Vector{<:Individual},
    evaluation::ScalarFitnessEvaluation
)
    ids = [individual.id for individual in new_population]
    records_dict = Dict(record.id => record for record in evaluation.records)
    fitnesses = [records_dict[id].fitness for id in ids]
    parent_indices = roulette(rng, selector.n_parents, fitnesses)
    parents = [new_population[i] for i in parent_indices]
    return parents  
end

end