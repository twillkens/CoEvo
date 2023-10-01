"""
    Evaluations

This module provides definitions and functions to evaluate individuals based on 
scalar fitness and sort them according to specific criteria, either maximizing or minimizing the fitness.
"""
module ScalarFitness

export ScalarFitnessEvaluation, ScalarFitnessEvaluator

using ....Species.Abstract: AbstractSpecies
using ....Species.Interfaces: get_all_individuals
using ....Species.Individuals.Abstract: Individual
using ...Evaluators.Abstract: Evaluation, Evaluator

import ...Evaluators.Interfaces: create_evaluation


struct ScalarFitnessEvaluation <: Evaluation
    species_id::String
    fitnessess::OrderedDict{Int, Float64}
end

Base.@kwdef struct ScalarFitnessEvaluator <: Evaluator 
    maximize::Bool = true
    epsilon::Float64 = 1e-6
end

function create_evaluation(
    evaluator::ScalarFitnessEvaluator,
    species::AbstractSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}}
) 
    indiv_ids = [indiv.id for indiv in get_all_individuals(species)]
    outcome_sums = [
        sum(outcomes[indiv_id][partner_id] 
        for partner_id in keys(outcomes[indiv_id]))
        for indiv_id in indiv_ids
    ]
    if evaluator.maximize
        fitnesses = outcome_sums
    else
        shift_value = abs(minimum(outcome_sums) + evaluator.epsilon)
        fitnesses = outcome_sums .+ shift_value
    end

    indiv_fitnesses = Dict(
        indiv_ids[i] => fitnesses[i] for i in eachindex(indiv_ids)
    )
    reverse = !evaluator.maximize
    indiv_fitnesses = OrderedDict(sort(collect(indiv_fitnesses), by = x-> x[2], rev=reverse))
    evaluation = ScalarFitnessEvaluation(species.id, indiv_fitnesses)
    return evaluation
end

end
