export evaluate

using ..Abstract

function evaluate(
    evaluator::Evaluator, 
    species::AbstractSpecies,
    results::Vector{Result},
    state::State
)
    evaluator = typeof(evaluator)
    species = typeof(species)
    results = typeof(results)
    state = typeof(state)
    error("evaluate not implemented for $evaluator, $species, $results, $state.")
end