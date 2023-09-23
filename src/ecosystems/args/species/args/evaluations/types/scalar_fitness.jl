export ScalarFitnessEvaluation, ScalarFitnessEvaluationConfiguration

using .....CoEvo.Abstract: Evaluation, EvaluationConfiguration, Individual
using ..Utilities: Max, Min
"""
    ScalarFitnessEval

Represents an evaluation based on scalar fitness.

# Fields
- `id::Int`: The identifier for the evaluation.
- `fitness::Float64`: The fitness score associated with this evaluation.
"""
struct ScalarFitnessEvaluation{I <: Individual} <: Evaluation
    int::I
    fitness::Float64
end

"""
    ScalarFitnessEvalCfg <: EvaluationConfiguration

A configuration for scalar fitness evaluations. This serves as a placeholder for potential configuration parameters.
"""
Base.@kwdef struct ScalarFitnessEvaluationConfiguration <: EvaluationConfiguration end

function(eval_cfg::ScalarFitnessEvaluationConfiguration)(
    indiv::Individual, outcomes::Dict{Int, Float64}
)
    fitness = sum(val for val in values(outcomes))
    return ScalarFitnessEvaluationConfiguration(indiv.id, fitness)
end

function sort_evaluations(evals::Vector{ScalarFitnessEvaluation}, ::Max)
    sort(evals, by = i -> i.fitness, rev = true)
end

function sort_evaluations(evals::Vector{ScalarFitnessEvaluation}, ::Min)
    sort(evals, by = i -> i.fitness, rev = false)
end