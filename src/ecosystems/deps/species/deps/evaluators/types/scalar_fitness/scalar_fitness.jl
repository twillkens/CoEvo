module ScalarFitness

export ScalarFitnessEvaluation, ScalarFitnessEvaluator

using DataStructures: OrderedDict
using ....Species.Abstract: AbstractSpecies
using ....Species.Individuals: Individual
using ...Evaluators.Abstract: Evaluation, Evaluator

import ...Evaluators.Interfaces: create_evaluation, get_ranked_ids


struct ScalarFitnessEvaluation <: Evaluation
    species_id::String
    fitnesses::OrderedDict{Int, Float64}
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
    indiv_ids = [indiv.id for indiv in values(merge(species.pop, species.children))] 
    outcome_sums = [
        sum(outcomes[indiv_id][partner_id] 
        for partner_id in keys(outcomes[indiv_id]))
        for indiv_id in indiv_ids
    ]
    if evaluator.maximize
        fitnesses = outcome_sums
    else
        shift_value = abs(minimum(outcome_sums) + evaluator.epsilon)
        fitnesses = outcome_sums .- shift_value
    end

    indiv_fitnesses = Dict(
        indiv_ids[i] => fitnesses[i] for i in eachindex(indiv_ids)
    )
    reverse = evaluator.maximize
    indiv_fitnesses = OrderedDict(sort(collect(indiv_fitnesses), by = x-> x[2], rev=reverse))
    evaluation = ScalarFitnessEvaluation(species.id, indiv_fitnesses)
    return evaluation
end

function get_ranked_ids(evaluator::ScalarFitnessEvaluation, ids::Vector{Int})
    ranked_ids = filter(
        indiv_id -> indiv_id in ids, keys(evaluator.fitnesses)
    )
    return ranked_ids
end


end
