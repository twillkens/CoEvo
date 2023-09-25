module Selectors

export IdentitySelector, FitnessProportionateSelector

module Abstract

using Random: AbstractRNG
using DataStructures: OrderedDict
using .....CoEvo.Abstract: Individual, Evaluation, Selector

function(selector::Selector)(
    rng::AbstractRNG, 
    new_pop_evals::OrderedDict{<:I, <:E}, 
)::OrderedDict{<:Individual, <:Evaluation} where {I <: Individual, E <: Evaluation}
    throw(ErrorException(
        "Selector $S not implemented for individual type $I and evaluation type $E")
    )
end

end

using .Abstract
include("types/identity.jl")
include("types/fitness_proportionate.jl")
# include("types/tournament.jl")

end