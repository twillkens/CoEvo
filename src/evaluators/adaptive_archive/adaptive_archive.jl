module AdaptiveArchive

export AdaptiveArchiveEvaluator, AdaptiveArchiveEvaluation

import ...Evaluators: evaluate

using Random: AbstractRNG
using ...Evaluators: Evaluator, Evaluation
using ...Evaluators.ScalarFitness: ScalarFitnessEvaluator, ScalarFitnessEvaluation
using ...Species.AdaptiveArchive: AdaptiveArchiveSpecies
using ...Individuals: get_individuals

struct AdaptiveArchiveEvaluation{E <: Evaluation} <: Evaluation
    id::String
    non_archive_evaluation::ScalarFitnessEvaluation
    full_evaluation::E
end

Base.@kwdef struct AdaptiveArchiveEvaluator{E <: Evaluator} <: Evaluator
    non_archive_evaluator::ScalarFitnessEvaluator
    full_evaluator::E
end

function filter_negative_ids(outcomes::Dict{Int, Dict{Int, Float64}})
    filtered_outcomes = Dict{Int, Dict{Int, Float64}}()
    for (id, outcome_dict) in outcomes
        if id > 0
            filtered_outcomes[id] = Dict{Int, Float64}()
            for (opposing_id, outcome) in outcome_dict
                if opposing_id > 0
                    filtered_outcomes[id][opposing_id] = outcome
                end
            end
        end
    end
    return filtered_outcomes
end


# TODO: We have a hack here where we assume the maximum outcome is 1.0 for the prediction game
# A fix will be to implement outcome types
function evaluate(
    evaluator::AdaptiveArchiveEvaluator,
    random_number_generator::AbstractRNG,
    species::AdaptiveArchiveSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}}
)
    non_archive_outcomes = filter_negative_ids(outcomes)
    full_outcomes = Dict(id => outcomes[id] for id in keys(outcomes) if id > 0)

    non_archive_evaluation = evaluate(
        evaluator.non_archive_evaluator, 
        random_number_generator, 
        species.basic_species, 
        non_archive_outcomes
    )
    full_evaluation = evaluate(
        evaluator.full_evaluator, 
        random_number_generator, 
        species.basic_species, 
        full_outcomes
    )
    evaluation = AdaptiveArchiveEvaluation(
        species.id, non_archive_evaluation, full_evaluation
    )
    return evaluation
end

end