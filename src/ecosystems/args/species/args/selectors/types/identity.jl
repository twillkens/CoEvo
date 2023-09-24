using Random: AbstractRNG
using DataStructures: OrderedDict
using ....CoEvo.Abstract: Individual, Selector, Evaluation

# abstract type Selector end
struct IdentitySelector <: Selector
end

function(s::IdentitySelector)(::AbstractRNG, evals::OrderedDict{<:Individual, <:Evaluation})
    [eval.id for eval in keys(evals)]
end