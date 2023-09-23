# This module contains 
module Selectors

export IdentitySelector, RouletteSelector, TournamentSelector

include("types/identity.jl")
include("types/roulette.jl")
include("types/tournament.jl")

using StatsBase
using Random
using ....CoEvo.Abstract: Individual, Selector, Evaluation
using ..Evaluations: ScalarFitnessEval


function(selector::Selector)(
    rng::AbstractRNG, 
    pop::OrderedDict(Int, <:Individual), 
    pop_evals::Dict{Int, <:Evaluation},
    children_evals::Dict{Int, <:Evaluation},
)
    parents = selector(rng, pop, merge(pop_evals, children_evals))
    return parents
end


end