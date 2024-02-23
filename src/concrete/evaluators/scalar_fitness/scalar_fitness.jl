module ScalarFitness

export ScalarFitnessEvaluation, ScalarFitnessEvaluator, ScalarFitnessRecord

import ....Interfaces: evaluate
using ....Abstract
using ....Interfaces
using ...Matrices.Outcome: OutcomeMatrix, make_distinction_matrix
using Random: AbstractRNG
using DataStructures: SortedDict
using StatsBase: mean
import Base: getproperty

struct ScalarFitnessRecord{I <: Individual} <: Record
    id::Int
    individual::I
    raw_fitness::Float64
    scaled_fitness::Float64
end

function getproperty(record::ScalarFitnessRecord, name::Symbol)
    if name == :fitness
        return record.scaled_fitness
    end
    return getfield(record, name)
end

struct ScalarFitnessEvaluation{R <: ScalarFitnessRecord, M <: OutcomeMatrix} <: Evaluation
    id::String
    records::Vector{R}
    matrix::M
end

Base.@kwdef struct ScalarFitnessEvaluator <: Evaluator 
    id::String = "A"
    objective::String = "performance"
    maximize::Bool = true
    maximum_fitness::Union{Nothing, Float64} = nothing
    epsilon::Float64 = 1e-6
end

function get_scaled_fitnesses(
    raw_fitnesses::Vector{Float64};
    maximize::Bool = true, 
    maximum_fitness::Float64 = 1.0, 
    epsilon::Float64 = 1e-6
)
    raw_fitnesses = maximize ? raw_fitnesses : -raw_fitnesses
    min_fitness = minimum(raw_fitnesses)
    shift_value = (min_fitness <= 0) ? abs(min_fitness) + epsilon : 0
    raw_fitnesses .+= shift_value
    scaled_fitnesses = raw_fitnesses ./ maximum_fitness
    return scaled_fitnesses
end

get_scaled_fitnesses(x::Vector{<:Real}; kwargs...) = get_scaled_fitnesses(float.(x); kwargs...)

function evaluate(
    evaluator::ScalarFitnessEvaluator,
    species::AbstractSpecies,
    matrix::OutcomeMatrix,
    state::State
)
    raw_fitnesses = [sum(row) for row in eachrow(matrix.data)]
    maximum_fitness = evaluator.maximum_fitness === nothing ? 
        float(length(matrix.column_ids)) : evaluator.maximum_fitness

    scaled_fitnesses = get_scaled_fitnesses(
        raw_fitnesses; 
        maximize = evaluator.maximize, 
        maximum_fitness = maximum_fitness, 
        epsilon = evaluator.epsilon
    )

    records = [
        ScalarFitnessRecord(id, species[id], raw_fitnesses[i], scaled_fitnesses[i])
        for (i, id) in enumerate(matrix.row_ids)
    ]

    sort!(records, by = x -> (x.scaled_fitness, rand(state.rng)), rev = true)

    evaluation = ScalarFitnessEvaluation(species.id, records, matrix)
    return evaluation
end

function evaluate(
    evaluator::ScalarFitnessEvaluator, 
    species::AbstractSpecies,
    results::Vector{<:Result},
    state::State
)
    if evaluator.objective == "performance"
        matrix = OutcomeMatrix(species.population, results)
    elseif evaluator.objective == "distinctions"
        matrix = make_distinction_matrix(species.population, results)
    else
        error("Invalid objective: $(evaluator.objective)")
    end
    evaluation = evaluate(evaluator, species, matrix, state)
    return evaluation
end



end
