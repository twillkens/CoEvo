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
    outcome_sums::Vector{Float64}
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
    indiv_ids = [indiv.id for indiv in values(merge(species.pop, species.children)) if indiv.id in keys(outcomes)]
    outcome_sums = [
        sum(outcomes[indiv_id][partner_id] 
        for partner_id in keys(outcomes[indiv_id]))
        for indiv_id in indiv_ids 
    ]
    fitnesses = evaluator.maximize ? outcome_sums : -outcome_sums
    min_fitness = minimum(fitnesses)
    shift_value = (min_fitness <= 0) ? abs(min_fitness) + evaluator.epsilon : 0
    fitnesses .+= shift_value

    indiv_fitnesses = Dict(
        indiv_ids[i] => fitnesses[i] for i in eachindex(indiv_ids)
    )
    indiv_fitnesses = OrderedDict(sort(collect(indiv_fitnesses), by = x-> x[2], rev=true))
    println(collect(values(indiv_fitnesses))[1:10])
    evaluation = ScalarFitnessEvaluation(species.id, indiv_fitnesses, outcome_sums)
    return evaluation
end

function get_ranked_ids(evaluator::ScalarFitnessEvaluation, ids::Vector{Int})
    ranked_ids = filter(
        indiv_id -> indiv_id in ids, keys(evaluator.fitnesses)
    )
    return ranked_ids
end


end
