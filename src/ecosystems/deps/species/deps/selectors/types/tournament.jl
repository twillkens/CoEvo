module Tournament

using ...Selectors.Abstract: Selector
using StatsBase: sample
using Random: AbstractRNG
using ....Evaluators.Interfaces: get_ranked_ids
using ....Evaluators.Types.ScalarFitness: ScalarFitnessEvaluation
using ....Evaluators.Types.NSGAII: NSGAIIEvaluation
using ....Species.Individuals: Individual

import ...Selectors.Interfaces: select


Base.@kwdef struct TournamentSelector <: Selector
    μ::Int # number of parents to select
    tournament_size::Int # tournament size
    selection_func::Function = argmax # function to select the winner of the tournament
end

"""
    (s::TournamentSelector)(rng::AbstractRNG, pop::Vector{<:Individual}, evals::Dict{Int, ScalarFitnessEval})

Executes the tournament selection strategy.

# Arguments
- `rng::AbstractRNG`: A random number generator.
- `pop::Vector{<:Individual}`: Vector of individuals in the population.
- `evals::Dict{Int, ScalarFitnessEval}`: A dictionary mapping individual IDs to their evaluations.

# Returns
- `Vector{Individual}`: A list of selected parent individuals.
"""
function select(
    selector::TournamentSelector,
    rng::AbstractRNG, 
    new_pop::Dict{Int, <:Individual},
    evaluation::NSGAIIEvaluation
)
    ranked_ids = get_ranked_ids(evaluation, collect(keys(new_pop)))
    parent_idxs = Array{Int}(undef, selector.μ)
    for i in 1:selector.μ
        tournament_idxs = sample(rng, 1:length(ranked_ids), selector.tournament_size, replace=false)
        parent_idx = selector.selection_func(tournament_idxs)
        parent_idxs[i] = ranked_ids[parent_idx]
    end
    parents = [new_pop[idx] for idx in parent_idxs]
    return parents
end

end