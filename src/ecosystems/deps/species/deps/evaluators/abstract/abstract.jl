"""
    Abstract

This module provides abstract definitions and basic functionalities that can be 
extended for specific evaluation strategies in the co-evolutionary framework.
"""
module Abstract

export Evaluator, Evaluation
export Criterion
export create_evaluation, sort_indiv_evals

abstract type Evaluation end
abstract type Evaluator end
abstract type Criterion end

using DataStructures: OrderedDict
using ....Species.Individuals.Abstract: Individual



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
    sort_criterion::Criterion, indiv_evals::OrderedDict{<:Individual, Evaluation}
) 
    throw(ErrorException(
        "`sort_indiv_evals` not implemented for criterion $sort_criterion for $indiv_evals."))
end

end
