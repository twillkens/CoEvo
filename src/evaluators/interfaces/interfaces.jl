export evaluate, get_raw_fitnesses, get_scaled_fitnesses

# TODO: Add observations to the interface.

function evaluate(
    evaluator::Evaluator,
    random_number_generator::AbstractRNG,
    species::AbstractSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}},
    #observations::Vector{<:Observation}
)
    throw(ErrorException(
        "`evaluate` not implemented for $evaluator and $species."))
end

function evaluate(
    evaluators::Vector{<:Evaluator},
    random_number_generator::AbstractRNG,
    species::Vector{<:AbstractSpecies},
    individual_outcomes::Dict{Int, Dict{Int, Float64}},
    #observations::Vector{<:Observation},
)
    evaluations = [
        evaluate(evaluator, random_number_generator, species, individual_outcomes)
        for (evaluator, species) in zip(evaluators, species)
    ]
    
    return evaluations
end

function get_raw_fitnesses(evaluation::Evaluation)
    throw(ErrorException(
        "`get_raw_fitnesses` not implemented for $evaluation.")
    )
end

function get_scaled_fitnesses(evaluation::Evaluation)
    throw(ErrorException(
        "`get_scaled_fitnesses` not implemented for $evaluation.")
    )
end
