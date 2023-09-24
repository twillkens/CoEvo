module Replacers

export IdentityReplacer
# export TruncationReplacer
# export GenerationalReplacer

include("types/identity.jl")
# include("types/truncation.jl")
# include("types/generational.jl")

using Random: AbstractRNG
using DataStructures: OrderedDict
using ....CoEvo.Abstract: Replacer, Evaluation, AbstractSpecies, Individual


function(replacer::Replacer)(
    rng::AbstractRNG, 
    pop_evals::OrderedDict{<:Individual, <:Evaluation},
    children_evals::OrderedDict{<:Individual, <:Evaluation},
)
    new_pop_indices = replacer(rng, collect(values(pop_evals)), collect(values(children_evals)))
    new_pop_evals = OrderedDict(filter(
        pair -> first(pair).id ∈ new_pop_indices, 
        merge(pop_evals, children_evals)
    ))
    return new_pop_evals
end


end