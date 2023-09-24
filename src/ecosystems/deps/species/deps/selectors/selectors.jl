# This module contains 
module Selectors

export IdentitySelector, RouletteSelector, TournamentSelector

include("types/identity.jl")
# include("types/roulette.jl")
# include("types/tournament.jl")

using DataStructures: OrderedDict
using Random: AbstractRNG
using ....CoEvo.Abstract: Individual, Selector, Evaluation


function(selector::Selector)(
    rng::AbstractRNG, 
    new_pop_evals::OrderedDict{<:Individual, <:Evaluation}, 
)
    parent_evals = selector(rng, new_pop_evals)
    parents = collect(keys(parent_evals))
    return parents
end


end