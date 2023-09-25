export IdentityReplacer

using Random: AbstractRNG
using DataStructures: OrderedDict
using ....CoEvo.Abstract: Individual, Evaluation, Replacer

struct IdentityReplacer <: Replacer end

function(r::IdentityReplacer)(
    ::AbstractRNG, 
    pop_evals::OrderedDict{<:Individual, <:Evaluation},
    children_evals::OrderedDict{<:Individual, <:Evaluation}
)
    if length(pop_evals) > 0
        return pop_evals
    else
        return children_evals
    end
end
