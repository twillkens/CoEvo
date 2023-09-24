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
    parent_ids = selector(rng, new_pop_evals)
    println("pids: ", parent_ids)
    parents = filter(
        (indiv, _) -> indiv.id in parent_ids, 
        new_pop_evals
    )
    parents = [indiv for (indiv, _) in parents]
    return parents
end


end