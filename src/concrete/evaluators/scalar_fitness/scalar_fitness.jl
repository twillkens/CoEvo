module ScalarFitness

export ScalarFitnessEvaluation, ScalarFitnessEvaluator, ScalarFitnessRecord
export evaluate, get_record

import ....Interfaces: evaluate

using Random: AbstractRNG
using DataStructures: SortedDict
using StatsBase: mean
using ....Abstract
using ....Interfaces

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
    evaluation_time::Float64 = 0.0
end

function evaluate(
    evaluator::ScalarFitnessEvaluator,
    species::AbstractSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}},
    state::State
)
    individuals = get_individuals_to_evaluate(species)
    for individual in individuals
        if !haskey(outcomes, individual.id)
            error("No outcomes for individual with id $(individual.id)")
        end
    end
    ##println("n individuals: ", length(individuals))
    #if length(individuals) == 0
    #    return ScalarFitnessEvaluation(species.id, ScalarFitnessRecord[])
    #end
    #filter!(individual -> individual.id in keys(outcomes), individuals)
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

    sort!(records, by = x -> (x.scaled_fitness, rand(state.rng)), rev = true)

    evaluation = ScalarFitnessEvaluation(species.id, records)
    #println("rng state after evaluation: ", rng.state)
    return evaluation
end



end
