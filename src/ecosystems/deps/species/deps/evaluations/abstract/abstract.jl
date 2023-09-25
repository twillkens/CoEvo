
module Abstract

export sort_indiv_evals

using DataStructures: OrderedDict
using .....CoEvo.Abstract: Individual, Evaluation, Criterion
using .....CoEvo.Utilities.Criteria: NullCriterion

function sort_indiv_evals(
    sort_criterion::C, indiv_evals::OrderedDict{<:Individual, E}
) where {C <: Criterion, E <: Evaluation}
    throw(ErrorException(
        "`sort_indiv_evals`` not implemented for criterion $C with evaluation type $E."))
end

function sort_indiv_evals(
    ::NullCriterion, 
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    return indiv_evals
end

end