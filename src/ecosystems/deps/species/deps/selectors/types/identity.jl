using Random: AbstractRNG
using DataStructures: OrderedDict
using ....CoEvo.Abstract: Individual, Selector, Evaluation

# abstract type Selector end
struct IdentitySelector <: Selector end

function(selector::IdentitySelector)(
    ::AbstractRNG, 
    parent_evals::OrderedDict{<:Individual, <:Evaluation}
)
    parent_evals
end