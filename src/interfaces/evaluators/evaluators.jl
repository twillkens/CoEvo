export evaluate, evaluate_with_time

using ..Abstract

function evaluate(
    evaluator::Evaluator, 
    species::AbstractSpecies,
    results::Vector{<:Result},
    state::State
)
    evaluator = typeof(evaluator)
    species = typeof(species)
    results = typeof(results)
    state = typeof(state)
    error("evaluate not implemented for $evaluator, $species, $results, $state.")
end

function evaluate(
    ecosystem::Ecosystem, evaluators::Vector{<:Evaluator}, results::Vector{<:Result}, state::State
)
    ecosystem = typeof(ecosystem)
    evaluators = typeof(evaluators)
    results = typeof(results)
    state = typeof(state)
    error("evaluate not implemented for $ecosystem, $evaluators, $results, $state.")
end

function evaluate_with_time(
    ecosystem::Ecosystem, 
    evaluators::Vector{<:Evaluator},
    results::Vector{<:Result}, 
    state::State
)
    evaluation_time_start = time()
    evaluations = evaluate(ecosystem, evaluators, results, state)
    evaluation_time = round(time() - evaluation_time_start; digits = 3)
    return evaluations, evaluation_time
end
