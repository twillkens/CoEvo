module Disco

export DiscoEvaluator, DiscoEvaluation, DiscoRecord
export create_records, evaluate

import ....Interfaces: evaluate
import Base: getproperty
using ....Interfaces
using ....Abstract
using ...Criteria
using ...Matrices.Outcome
using ...Evaluators.NSGAII

Base.@kwdef struct DiscoEvaluator <: Evaluator 
    maximize::Bool = true
    objective::String = "performance"
    max_clusters::Int = 5
    clusterer::String = "global_kmeans"
    distance_method::String = "euclidean"
    function_minimums::Union{Vector{Float64}, Nothing} = nothing
    function_maximums::Union{Vector{Float64}, Nothing} = nothing
end

Base.@kwdef mutable struct DiscoRecord{I <: Individual} <: Record
    id::Int = 0
    individual::I
    raw_outcomes::Vector{Float64} = Float64[]
    outcomes::Vector{Float64} = Float64[]
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
end

function getproperty(record::DiscoRecord, name::Symbol)
    if name == :fitness
        return sum(record.raw_outcomes)
    end
    return getfield(record, name)
end

Base.@kwdef struct DiscoEvaluation{
    R <: DiscoRecord, M1 <: OutcomeMatrix, M2 <: OutcomeMatrix
} <: Evaluation
    id::String
    records::Vector{R}
    raw_matrix::M1
    matrix::M2
end

function create_records(
    evaluator::DiscoEvaluator,
    species::AbstractSpecies,
    raw_matrix::OutcomeMatrix,
    matrix::OutcomeMatrix
)
    records = []
    for id in matrix.row_ids
        record = DiscoRecord(
            id = id, 
            individual = species[id],
            raw_outcomes = raw_matrix[id, :], 
            outcomes = matrix[id, :]
        )
        push!(records, record)
    end
    records = [r for r in records]
    criterion = evaluator.maximize ? Maximize() : Minimize()
    sorted_records = nsga_sort!(
        records, criterion, evaluator.function_minimums, evaluator.function_maximums
    )
    return sorted_records
end

using DataStructures
using ...Clusterers.GlobalKMeans: get_derived_tests

function get_derived_matrix(
    rng::AbstractRNG,
    matrix::OutcomeMatrix,
    max_clusters::Int = 5,
    distance_method::String = "euclidean"
)
    indiv_tests = SortedDict(id => float.(matrix[id, :]) for id in matrix.row_ids)
    derived_tests = get_derived_tests(rng, indiv_tests, max_clusters, distance_method)
    n_derived_tests = length(first(collect(values(derived_tests))))
    derived_data = zeros(Float64, length(matrix.row_ids), n_derived_tests)
    for (i, derived_test) in enumerate(values(derived_tests))
        derived_data[i, :] = derived_test
    end
    derived_matrix = OutcomeMatrix(
        "derived", matrix.row_ids, collect(1:n_derived_tests), derived_data
    )
    return derived_matrix
end

function evaluate(
    evaluator::DiscoEvaluator,
    species::AbstractSpecies,
    raw_matrix::OutcomeMatrix,
    state::State
)
    matrix = get_derived_matrix(
        state.rng, raw_matrix, evaluator.max_clusters, evaluator.distance_method
    )
    records = create_records(evaluator, species, raw_matrix, matrix)
    evaluation = DiscoEvaluation(
        id = species.id, records = records, raw_matrix = matrix, matrix = matrix
    )
    return evaluation
end

function evaluate(
    evaluator::DiscoEvaluator,
    species::AbstractSpecies,
    results::Vector{<:Result},
    state::State
)
    if evaluator.objective == "performance"
        raw_matrix = OutcomeMatrix(species, results)
    elseif evaluator.objective == "distinction"
        raw_matrix = make_distinction_matrix(species, results)
    else
        error("Objective must be either 'performance' or 'distinction'")
    end
    evaluation = evaluate(evaluator, species, raw_matrix, state)
    return evaluation
end

end