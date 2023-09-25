export ScalarFitnessEvaluation, ScalarFitnessEvaluationConfiguration

using DataStructures: OrderedDict
using .....CoEvo.Abstract: Evaluation, EvaluationConfiguration, Individual, Criterion
using .....CoEvo.Utilities.Criteria: Maximize, Minimize

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
    sort_criterion::Criterion = Maximize()
end

function(eval_cfg::ScalarFitnessEvaluationConfiguration)(
    indiv::Individual, outcomes::Dict{Int, Float64}
)
    fitness = sum(val for val in values(outcomes))
    return ScalarFitnessEvaluation(indiv.id, fitness)
end

function sort_indiv_evals(
    ::Maximize,
    indiv_evals::OrderedDict{<:Individual, ScalarFitnessEvaluation}
)
    # Sorting the OrderedDict by fitness in descending order for maximization
    # The most fit is at the front of the OrderedDict and the least fit is at the back
    sorted_indiv_evals = OrderedDict(
        sort(collect(indiv_evals), by = pair -> pair.second.fitness, rev = true)
    )
    return sorted_indiv_evals
end

function sort_indiv_evals(
    ::Minimize,
    indiv_evals::OrderedDict{<:Individual, ScalarFitnessEvaluation}
)
    # Sorting the OrderedDict by fitness in ascending order for minimization
    # The most fit is at the front of the OrderedDict and the least fit is at the back
    sorted_indiv_evals = OrderedDict(
        sort(collect(indiv_evals), by = pair -> pair.second.fitness, rev = false)
    )
    return sorted_indiv_evals
end

function(eval_cfg::ScalarFitnessEvaluationConfiguration)(
    all_indiv_outcomes::Dict{<:Individual, Dict{Int, Float64}}
) 
    evals = [eval_cfg(indiv, outcomes) for (indiv, outcomes) in all_indiv_outcomes]
    id_indiv_dict = Dict(indiv.id => indiv for indiv in keys(all_indiv_outcomes))
    indiv_evals = OrderedDict(id_indiv_dict[eval.id] => eval for eval in evals)
    indiv_evals = sort_indiv_evals(eval_cfg.sort_criterion, indiv_evals)
    return indiv_evals
end

