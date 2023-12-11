export evaluate, get_raw_fitnesses, get_scaled_fitnesses, get_scaled_fitness

# TODO: Add observations to the interface.

function evaluate(
    evaluator::Evaluator,
    random_number_generator::AbstractRNG,
    species::AbstractSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}},
    #observations::Vector{<:Observation}
)
    throw(ErrorException(
        "`evaluate` not implemented for $(typeof(evaluator)) and $(typeof(species))."))
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

function get_scaled_fitness(evaluation::Evaluation, id::Int)
    throw(ErrorException(
        "`get_scaled_fitness` not implemented for $evaluation.")
    )
end

function get_scaled_fitness(evaluations::Vector{<:Evaluation}, id::Int)
    for evaluation in evaluations
        for record in evaluation.records
            if record.id == id
                return record.scaled_fitness
            end
        end
    end
    throw(ErrorException("Could not find individual with id $id in get_scaled_fitness."))
end

