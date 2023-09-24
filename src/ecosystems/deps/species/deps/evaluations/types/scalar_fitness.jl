export ScalarFitnessEvaluation, ScalarFitnessEvaluationConfiguration

using DataStructures: OrderedDict
using .....CoEvo.Abstract: Evaluation, EvaluationConfiguration, Individual, Sense
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
    indiv::Individual, outcomes::Dict{Int, Float64}
)
    fitness = sum(val for val in values(outcomes))
    return ScalarFitnessEvaluation(indiv.id, fitness)
end

function sort_evaluations(evals::Vector{ScalarFitnessEvaluation}, ::Max)
    evals = sort(evals, by = i -> i.fitness, rev = true)
    return evals
end
function sort_evaluations(evals::Vector{ScalarFitnessEvaluation}, ::Min)
    evals = sort(evals, by = i -> i.fitness, rev = false)
    return evals
end


function(eval_cfg::ScalarFitnessEvaluationConfiguration)(
    all_indiv_outcomes::Dict{I, Dict{Int, Float64}}
) where {I <: Individual}
    evals = [eval_cfg(indiv, outcomes) for (indiv, outcomes) in all_indiv_outcomes]
    evals = sort_evaluations(evals, eval_cfg.is_better)
    indiv_dict = Dict(indiv.id => indiv for indiv in keys(all_indiv_outcomes))
    indiv_evals = OrderedDict(indiv_dict[eval.id] => eval for eval in evals)
    return indiv_evals
end

