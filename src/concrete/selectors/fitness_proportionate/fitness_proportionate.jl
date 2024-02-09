module FitnessProportionate

export FitnessProportionateSelector, roulette

import ....Interfaces: select
using ....Abstract
using ...Selectors.Selections: BasicSelection
using Random
using DataStructures: OrderedDict

Base.@kwdef struct FitnessProportionateSelector <: Selector
    n_selections::Int
    n_selection_set::Int
end

function roulette(rng::AbstractRNG, n_spins::Int, fitnesses::Vector{<:Real})
    if any(fitnesses .<= 0)
        throw(ArgumentError("Fitness values must be strictly positive for FitnessProportionateSelector."))
    end
    probabilities = fitnesses ./ sum(fitnesses)
    cumulative_probabilities = cumsum(probabilities)
    winner_indices = Array{Int}(undef, n_spins)
    spins = rand(rng, n_spins)
    for (i, spin) in enumerate(spins)
        candidate_index = 1
        while cumulative_probabilities[candidate_index] < spin
            candidate_index += 1
        end
        winner_indices[i] = candidate_index
    end
    return winner_indices
end

function select(
    ::FitnessProportionateSelector, 
    records::Vector{<:Record},
    n_selection_set::Int,
    rng::AbstractRNG = Random.GLOBAL_RNG
)
    fitnesses = [record.fitness for record in records]
    winner_indices = roulette(rng, n_selection_set, fitnesses)
    selection_set = [records[i] for i in winner_indices]
    selection = BasicSelection(selection_set)
    return selection
end

function select(
    selector::FitnessProportionateSelector, 
    records::Vector{<:Record},
    n_selections::Int,
    n_selection_set::Int,
    rng::AbstractRNG = Random.GLOBAL_RNG;
)
    selections = BasicSelection[]
    for _ in 1:n_selections
        selection = select(selector, records, n_selection_set, rng)
        push!(selections, selection)
    end
    return selections
end

function select(selector::FitnessProportionateSelector, evaluation::Evaluation, state::State) 
    selections = select(
        selector, 
        evaluation.records,
        selector.n_selections,
        selector.n_selection_set,
        state.rng
    )
    return selections
end

end