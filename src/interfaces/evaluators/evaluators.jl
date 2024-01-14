export evaluate, get_raw_fitnesses, get_scaled_fitnesses, get_scaled_fitness, get_elite_ids
export get_elite_records, get_records

using ..Abstract


function evaluate(
    evaluator::Evaluator,
    species::AbstractSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}},
    state::State
)
    error("`evaluate` not implemented for $(typeof(evaluator)) and $(typeof(species)).")
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

function get_best_records(evaluation::Evaluation, n::Int)
    throw(ErrorException(
        "`get_best_ids` not implemented for $evaluation.")
    )
end

function get_worst_records(evaluation::Evaluation, n::Int)
    throw(ErrorException(
        "`get_worst_ids` not implemented for $evaluation.")
    )
end

function get_worst_records(evaluation::Evaluation, ids::Vector{Int}, n::Int)
    

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

function get_elite_ids(evaluation::Vector{<:Evaluation}, n::Int)
    throw(ErrorException(
        "`get_elite_ids` not implemented for $(typeof(evaluation)).")
    )
end

function get_elite_records(evaluation::Evaluation, n::Int)
    throw(ErrorException(
        "`get_elite_records` not implemented for $(typeof(evaluation)).")
    )
end


function get_records(evaluation::Evaluation, ids::Vector{Int})
    records = []
    for id in ids
        for record in evaluation.records
            if record.id == id
                push!(records, record)
            end
        end
    end
    records = [record for record in records]
    return records
end