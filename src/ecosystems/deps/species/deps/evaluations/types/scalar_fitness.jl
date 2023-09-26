"""
    Evaluations

This module provides definitions and functions to evaluate individuals based on 
scalar fitness and sort them according to specific criteria, either maximizing or minimizing the fitness.
"""
module ScalarFitness

export ScalarFitnessEvaluation, ScalarFitnessEvaluationConfiguration, sort_indiv_evals

using DataStructures: OrderedDict
using .....CoEvo.Abstract: Evaluation, EvaluationConfiguration, Individual, Criterion
using .....CoEvo.Utilities.Criteria: Maximize, Minimize
import ..Abstract: sort_indiv_evals

"""
    ScalarFitnessEval

Represents an evaluation based on scalar fitness.

# Fields
- `id::Int`: The identifier for the evaluation.
- `fitness::Float64`: The fitness score associated with this evaluation.
"""
struct ScalarFitnessEvaluation <: Evaluation
    id::Int
    fitness::Float64
end

"""
    ScalarFitnessEvalCfg <: EvaluationConfiguration

A configuration for scalar fitness evaluations. Serves as a placeholder for future 
configuration parameters with default behavior set to maximize the scalar fitness.

# Fields
- `sort_criterion::Criterion`: The criterion used to sort individuals (default is `Maximize`).
"""
Base.@kwdef struct ScalarFitnessEvaluationConfiguration <: EvaluationConfiguration 
    sort_criterion::Criterion = Maximize()
end

"""
    Create a `ScalarFitnessEvaluation` using the provided configuration.

Given an individual and a dictionary of outcomes, this function computes 
the scalar fitness as the sum of all outcome values and returns a `ScalarFitnessEvaluation`.

# Arguments
- `indiv::Individual`: The individual for which the evaluation is being created.
- `outcomes::Dict{Int, Float64}`: Dictionary of outcomes for the individual.

# Returns
- A `ScalarFitnessEvaluation` instance with computed fitness.
"""
function(eval_cfg::ScalarFitnessEvaluationConfiguration)(
    indiv::Individual, outcomes::Dict{Int, Float64}
)
    fitness = sum(val for val in values(outcomes))
    return ScalarFitnessEvaluation(indiv.id, fitness)
end

"""
    Sort individuals based on `Maximize` criterion.

Given an ordered dictionary of individuals and their scalar fitness evaluations, 
sorts the individuals in descending order of fitness.

# Arguments
- `indiv_evals::OrderedDict{<:Individual, ScalarFitnessEvaluation}`: Dictionary of individuals and evaluations.

# Returns
- A sorted `OrderedDict` of individuals and evaluations.
"""
function sort_indiv_evals(
    ::Maximize,
    indiv_evals::OrderedDict{<:Individual, ScalarFitnessEvaluation}
)
    sorted_indiv_evals = OrderedDict(
        sort(collect(indiv_evals), by = pair -> pair.second.fitness, rev = true)
    )
    return sorted_indiv_evals
end

"""
    Sort individuals based on `Minimize` criterion.

Given an ordered dictionary of individuals and their scalar fitness evaluations, 
sorts the individuals in ascending order of fitness.

# Arguments
- `indiv_evals::OrderedDict{<:Individual, ScalarFitnessEvaluation}`: Dictionary of individuals and evaluations.

# Returns
- A sorted `OrderedDict` of individuals and evaluations.
"""
function sort_indiv_evals(
    ::Minimize,
    indiv_evals::OrderedDict{<:Individual, ScalarFitnessEvaluation}
)
    sorted_indiv_evals = OrderedDict(
        sort(collect(indiv_evals), by = pair -> pair.second.fitness, rev = false)
    )
    return sorted_indiv_evals
end

"""
    Evaluate all individuals based on the provided scalar fitness configuration.

Given a dictionary of individuals and their outcomes, this function creates evaluations 
for each individual, sorts them based on the configuration's criterion, and returns an ordered dictionary.

# Arguments
- `all_indiv_outcomes::Dict{<:Individual, Dict{Int, Float64}}`: A dictionary mapping individuals to their outcomes.

# Returns
- A sorted `OrderedDict` of individuals and their evaluations.
"""
function(eval_cfg::ScalarFitnessEvaluationConfiguration)(
    all_indiv_outcomes::Dict{<:Individual, Dict{Int, Float64}}
) 
    evals = [eval_cfg(indiv, outcomes) for (indiv, outcomes) in all_indiv_outcomes]
    id_indiv_dict = Dict(indiv.id => indiv for indiv in keys(all_indiv_outcomes))
    indiv_evals = OrderedDict(id_indiv_dict[eval.id] => eval for eval in evals)
    indiv_evals = sort_indiv_evals(eval_cfg.sort_criterion, indiv_evals)
    return indiv_evals
end

end
