export DodoTestEvaluator, DodoTestRecord, DodoPromotions, DodoTestEvaluation

using ....Abstract
using ...Matrices.Outcome

Base.@kwdef struct DodoTestEvaluator <: Evaluator
    id::String = "A"
    min_clusters::Int = 1
    max_clusters::Int = 5
    maximize::Bool = true
    function_minimums::Union{Vector{Float64}, Nothing} = nothing
    function_maximums::Union{Vector{Float64}, Nothing} = nothing
    n_runs::Int = 10
end

Base.@kwdef mutable struct DodoTestRecord{I <: Individual} <: Record
    id::Int = 0
    individual::I
    raw_outcomes::Vector{Float64} = Float64[]
    outcomes::Vector{Float64} = Float64[]
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
end

function getproperty(record::DodoTestRecord, name::Symbol)
    if name == :fitness
        return sum(record.raw_outcomes)
    end
    return getfield(record, name)
end

Base.@kwdef struct DodoPromotions
    explorer_to_promote_ids::Vector{Int} = Int[]
    retiree_to_promote_ids::Vector{Int} = Int[]
    child_to_promote_ids::Vector{Int} = Int[]
    hillclimber_to_retire_ids::Vector{Int} = Int[]
end

Base.@kwdef struct DodoTestEvaluation{R <: DodoTestRecord} <: Evaluation
    id::String
    promotions::DodoPromotions
    raw_matrix::OutcomeMatrix
    matrix::OutcomeMatrix
    records::Vector{R}
end

function Base.getproperty(evaluation::DodoTestEvaluation, name::Symbol)
    if name == :explorer_to_promote_ids
        return evaluation.promotions.explorer_to_promote_ids
    elseif name == :retiree_to_promote_ids
        return evaluation.promotions.retiree_to_promote_ids
    elseif name == :child_to_promote_ids
        return evaluation.promotions.child_to_promote_ids
    elseif name == :hillclimber_to_retire_ids
        return evaluation.promotions.hillclimber_to_retire_ids
    else
        return getfield(evaluation, name)
    end
end