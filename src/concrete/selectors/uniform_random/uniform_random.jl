module UniformRandom

export UniformRandomSelector, random_select

import ....Interfaces: select
using ....Abstract
using ...Selectors.Selections: BasicSelection
using Random

Base.@kwdef struct UniformRandomSelector <: Selector
    n_selections::Int
    n_selection_set::Int
end

function random_select(rng::AbstractRNG, n_selections::Int, n_records::Int)
    # Uniformly select indices from the set of records
    winner_indices = rand(rng, 1:n_records, n_selections)
    return winner_indices
end

function select(
    ::UniformRandomSelector, 
    records::Vector{<:Record},
    n_selection_set::Int,
    rng::AbstractRNG = Random.GLOBAL_RNG
)
    n_records = length(records)
    winner_indices = random_select(rng, n_selection_set, n_records)
    selection_set = [records[i] for i in winner_indices]
    selection = BasicSelection(selection_set)
    return selection
end

function select(selector::UniformRandomSelector, records::Vector{<:Record}, state::State)
    selections = BasicSelection[]
    for _ in 1:selector.n_selections
        selection = select(selector, records, selector.n_selection_set, state.rng)
        push!(selections, selection)
    end
    return selections
end

function select(selector::UniformRandomSelector, evaluation::Evaluation, state::State) 
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
