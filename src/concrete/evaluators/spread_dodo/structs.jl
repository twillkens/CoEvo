export SpreadDodoEvaluator, SpreadDodoRecord, SpreadDodoEvaluation

using ....Abstract
using ...Matrices.Outcome

Base.@kwdef struct SpreadDodoEvaluator <: Evaluator
    id::String = "A"
    min_clusters::Int = 1
    max_clusters::Int = 5
    maximize::Bool = true
    function_minimums::Union{Vector{Float64}, Nothing} = nothing
    function_maximums::Union{Vector{Float64}, Nothing} = nothing
    n_runs::Int = 10
end

Base.@kwdef mutable struct SpreadDodoRecord{I <: Individual} <: Record
    id::Int = 0
    individual::I
    raw_outcomes::Vector{Float64} = Float64[]
    filtered_outcomes::Vector{Float64} = Float64[]
    outcomes::Vector{Float64} = Float64[]
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
end

function getproperty(record::SpreadDodoRecord, name::Symbol)
    if name == :raw_fitness
        return sum(record.raw_outcomes)
    elseif name == :filtered_fitness
        return sum(record.filtered_outcomes)
    elseif name == :fitness
        return sum(record.outcomes)
    end
    return getfield(record, name)
end

Base.@kwdef struct SpreadDodoEvaluation{
    R <: SpreadDodoRecord, M1 <: OutcomeMatrix, M2 <: OutcomeMatrix, M3 <: OutcomeMatrix
} <: Evaluation
    id::String
    cluster_leaders::Vector{Int}
    raw_matrix::M1
    filtered_matrix::M2
    matrix::M3
    records::Vector{R}
end