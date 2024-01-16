export evaluate

using ..Abstract

function evaluate(
    evaluator::Evaluator,
    species::AbstractSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}},
    state::State
)
    evaluator = typeof(evaluator)
    species = typeof(species)
    outcomes = typeof(outcomes)
    state = typeof(state)
    error("`evaluate` not implemented for $evaluator, $species, $outcomes, $state.")
end

function evaluate(
    evaluator::Evaluator,
    ecosystem::Ecosystem,
    results::Vector{<:Result},
    state::State
)
    individual_outcomes = get_individual_outcomes(results)
    evaluations = [
        evaluate(evaluator, species, individual_outcomes, state)
        for species in ecosystem.all_species
    ]
    return evaluations
end
