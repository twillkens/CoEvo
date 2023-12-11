module ScalarFitness

export ScalarFitnessEvaluation, ScalarFitnessEvaluator, ScalarFitnessRecord
export evaluate, get_record, get_raw_fitnesses, get_scaled_fitnesses, get_scaled_fitness

import ..Evaluators: evaluate, get_raw_fitnesses, get_scaled_fitnesses, get_scaled_fitness

using Random: AbstractRNG
using DataStructures: SortedDict
using StatsBase: mean
using ...Species: AbstractSpecies
using ...Individuals: Individual, get_individuals
using ..Evaluators: Evaluation, Evaluator

struct ScalarFitnessRecord
    id::Int
    outcomes::SortedDict{Int, Float64}
    outcome_sum::Float64
    raw_fitness::Float64
    scaled_fitness::Float64
    fitness::Float64
end

struct ScalarFitnessEvaluation <: Evaluation
    id::String
    records::Vector{ScalarFitnessRecord}
end

function get_record(evaluation::ScalarFitnessEvaluation, id::Int)
    for record in evaluation.records
        if record.id == id
            return record
        end
    end
    throw(ErrorException("Could not find record with id $id"))
end

Base.@kwdef struct ScalarFitnessEvaluator <: Evaluator 
    maximize::Bool = true
    maximum_fitness::Union{Nothing, Float64} = nothing
    epsilon::Float64 = 1e-6
end

function evaluate(
    evaluator::ScalarFitnessEvaluator,
    random_number_generator::AbstractRNG,
    species::AbstractSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}}
)
    individuals = get_individuals(species)
    filter!(individual -> individual.id in keys(outcomes), individuals)
    ids = [individual.id for individual in individuals]
    filtered_outcomes = Dict(id => outcomes[id] for id in ids if haskey(outcomes, id))

    # TODO: This is a hack until outcomes are implemented
    #outcome_sums = [sum(values(outcomes[id])) for id in ids]
    outcome_vectors = [values(filtered_outcomes[id]) for id in ids]
    maximum_fitness = length(first(outcome_vectors))
    outcome_sums = [sum(outcome_vector) for outcome_vector in outcome_vectors]
    raw_fitnesses = evaluator.maximize ? outcome_sums : -outcome_sums
    min_fitness = minimum(raw_fitnesses)
    shift_value = (min_fitness <= 0) ? abs(min_fitness) + evaluator.epsilon : 0
    raw_fitnesses .+= shift_value

    scaled_fitnesses = copy(raw_fitnesses)
    scaled_fitnesses ./= maximum_fitness

    #if !isnothing(evaluator.maximum_fitness)
    #    # Scale by maximum_fitness
    #    scaled_fitnesses = raw_fitnesses ./ evaluator.maximum_fitness
    #end
    fitnesses = scaled_fitnesses

    records = [
        ScalarFitnessRecord(
            id, 
            filtered_outcomes[id], 
            outcome_sums[i], 
            raw_fitnesses[i], 
            scaled_fitnesses[i],
            fitnesses[i]
        )
        for (i, id) in enumerate(ids)
    ]

    sort!(records, by = x -> (x.scaled_fitness, rand(random_number_generator)), rev = true)

    evaluation = ScalarFitnessEvaluation(species.id, records)
    return evaluation
end

function get_raw_fitnesses(evaluation::ScalarFitnessEvaluation)
    return [record.raw_fitness for record in evaluation.records]
end

function get_scaled_fitnesses(evaluation::ScalarFitnessEvaluation)
    return [record.scaled_fitness for record in evaluation.records]
end

function get_scaled_fitness(evaluation::ScalarFitnessEvaluation, id::Int)
    record = get_record(evaluation, id)
    return record.scaled_fitness
end

function get_scaled_fitness(evaluations::Vector{<:ScalarFitnessEvaluation}, id::Int)
    for evaluation in evaluations
        for record in evaluation.records
            if record.id == id
                return record.scaled_fitness
            end
        end
    end
    throw(ErrorException("Could not find id $id in evaluations."))
end

end
