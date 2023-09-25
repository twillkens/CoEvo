"""
    Abstract

This module provides abstract definitions and basic functionalities that can be 
extended for specific evaluation strategies in the co-evolutionary framework.
"""
module Abstract

export sort_indiv_evals

using DataStructures: OrderedDict
using .....CoEvo.Abstract: Individual, Evaluation, Criterion
using .....CoEvo.Utilities.Criteria: NullCriterion

"""
    sort_indiv_evals(sort_criterion::C, indiv_evals::OrderedDict{<:Individual, E})

Sort the individuals based on their evaluations using the specified criterion.

# Arguments
- `sort_criterion::C`: Criterion used to sort the evaluations.
- `indiv_evals::OrderedDict{<:Individual, E}`: A dictionary mapping individuals to their evaluations.

# Returns
- An `OrderedDict` of sorted individuals and evaluations.

# Errors
- Throws an error if the provided criterion and evaluation type combination is not implemented.
"""
function sort_indiv_evals(
    sort_criterion::C, indiv_evals::OrderedDict{<:Individual, E}
) where {C <: Criterion, E <: Evaluation}
    throw(ErrorException(
        "`sort_indiv_evals` not implemented for criterion $C with evaluation type $E."))
end

"""
    sort_indiv_evals(::NullCriterion, indiv_evals::OrderedDict{<:Individual, <:Evaluation})

For a `NullCriterion`, this method simply returns the provided `indiv_evals` unchanged.

# Arguments
- `indiv_evals::OrderedDict{<:Individual, <:Evaluation}`: A dictionary mapping individuals to their evaluations.

# Returns
- The unmodified `OrderedDict` of individuals and evaluations.
"""
function sort_indiv_evals(
    ::NullCriterion, 
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    return indiv_evals
end

end
