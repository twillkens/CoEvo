export ScalarFitnessEvaluation, ScalarFitnessEvaluationConfiguration

using DataStructures: OrderedDict
using .....CoEvo.Abstract: Evaluation, EvaluationConfiguration, Individual
using ..Utilities: Max, Min
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

A configuration for scalar fitness evaluations. This serves as a placeholder for potential configuration parameters.
"""
Base.@kwdef struct ScalarFitnessEvaluationConfiguration <: EvaluationConfiguration 
    is_better::Sense = Max()
end

function(eval_cfg::ScalarFitnessEvaluationConfiguration)(
    indiv::Individual, outcomes::Dict{<:Individual, Float64}
)
    fitness = sum(val for val in values(outcomes))
    return ScalarFitnessEvaluation(indiv.id, fitness)
end

function sort_evaluations(evals::Vector{Pair{<:Individual, ScalarFitnessEvaluation}}, ::Max)
    sorted_evals = OrderedDict(sort(evals, by = i -> i.second.fitness, rev = true))
    return sorted_evals
end

function sort_evaluations(evals::Vector{Pair{<:Individual, ScalarFitnessEvaluation}}, ::Min)
    sorted_evals = OrderedDict(sort(evals, by = i -> i.second.fitness, rev = false))
    return sorted_evals
end

function(eval_cfg::ScalarFitnessEvaluationConfiguration)(
    all_indiv_outcomes::Dict{<:Individual, Dict{<:Individual, Float64}}
)::Dict{<:Individual, ScalarFitnessEvaluation}
    evals = [indiv => eval_cfg(indiv, outcomes) for (indiv, outcomes) in all_indiv_outcomes]
    evals = sort_evaluations(evals, eval_cfg.is_better)
    return evals
end

