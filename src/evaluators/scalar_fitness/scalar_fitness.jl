module ScalarFitness

export ScalarFitnessEvaluation, ScalarFitnessEvaluator, ScalarFitnessRecord

import ..Evaluators: evaluate, get_fitnesses

using Random: AbstractRNG
using DataStructures: SortedDict
using StatsBase: mean
using ...Species: AbstractSpecies
using ...Individuals: Individual
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
    species_id::String
    records::Vector{ScalarFitnessRecord}
end

Base.@kwdef struct ScalarFitnessEvaluator <: Evaluator 
    maximize::Bool = true
    maximum_fitness::Union{Nothing, Float64} = nothing
    epsilon::Float64 = 1e-6
end

function evaluate(
    evaluator::ScalarFitnessEvaluator,
    ::AbstractRNG,
    species::AbstractSpecies,
    outcomes::Dict{Int, SortedDict{Int, Float64}}
)
    individuals = [species.population ; species.children]
    filter!(individual -> individual.id in keys(outcomes), individuals)
    ids = [individual.id for individual in individuals]
    filtered_outcomes = Dict(id => outcomes[id] for id in ids if haskey(outcomes, id))

    outcome_sums = [sum(values(outcomes[id])) for id in ids]
    raw_fitnesses = evaluator.maximize ? outcome_sums : -outcome_sums
    min_fitness = minimum(raw_fitnesses)
    shift_value = (min_fitness <= 0) ? abs(min_fitness) + evaluator.epsilon : 0
    raw_fitnesses .+= shift_value

    scaled_fitnesses = copy(raw_fitnesses)

    if !isnothing(evaluator.maximum_fitness)
        # Check if any values exceed maximum_fitness
        #if any(fitness -> fitness > evaluator.maximum_fitness + evaluator.epsilon, raw_fitnesses)
        #    println("raw_fitnesses: ", raw_fitnesses)
        #    println("maximum_fitness: ", evaluator.maximum_fitness)
        #    throw(ErrorException("Some fitness values exceed the defined maximum_fitness."))
        #end

        # Scale by maximum_fitness
        scaled_fitnesses = raw_fitnesses ./ evaluator.maximum_fitness
    end
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

    sort!(records, by = x -> (x.scaled_fitness, rand()), rev = true)

    evaluation = ScalarFitnessEvaluation(species.id, records)
    return evaluation
end

function get_fitnesses(evaluation::ScalarFitnessEvaluation)
    return [record.fitness for record in evaluation.records]
end

end