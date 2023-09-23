
using ....CoEvo.Abstract: Evaluation, EvaluationConfiguration
using ..Utilities: Max, Min
"""
    ScalarFitnessEval

Represents an evaluation based on scalar fitness.

# Fields
- `id::Int`: The identifier for the evaluation.
- `fitness::Float64`: The fitness score associated with this evaluation.
"""
struct ScalarFitnessEval{I <: Individual} <: Evaluation
    int::I
    fitness::Float64
end

"""
    ScalarFitnessEvalCfg <: EvaluationConfiguration

A configuration for scalar fitness evaluations. This serves as a placeholder for potential configuration parameters.
"""
Base.@kwdef struct ScalarFitnessEvalCfg <: EvaluationConfiguration end

function(eval_cfg::ScalarFitnessEvalCfg)(indiv::Individual, outcomes::Dict{Int, Float64})
    fitness = sum(val for val in values(outcomes))
    return ScalarFitnessEval(indiv.id, fitness)
end

function sort_evaluations(evals::Vector{ScalarFitnessEval}, ::Max)
    sort(evals, by = i -> i.fitness, rev = true)
end

function sort_evaluations(evals::Vector{ScalarFitnessEval}, ::Min)
    sort(evals, by = i -> i.fitness, rev = false)
end