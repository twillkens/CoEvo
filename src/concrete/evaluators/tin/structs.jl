export TinEvaluator, TinRecord, TinEvaluation

using ....Abstract
using ...Matrices.Outcome
using ...Matrices.Outcome: OutcomeMatrix

Base.@kwdef struct TinEvaluator <: Evaluator
    id::String = "A"
    objective::String = "performance"
    selection_method::String = "hillclimber"
    other_species_comparison_cohorts::Vector{String} = ["parents", "children"]
    min_clusters::Int = 1
    max_clusters::Int = 5
    maximize::Bool = true
    function_minimums::Union{Vector{Float64}, Nothing} = nothing
    function_maximums::Union{Vector{Float64}, Nothing} = nothing
    n_runs::Int = 10
    filter_zero_rows::Bool = false
    filter_zero_columns::Bool = false
    filter_duplicate_rows::Bool = false
    filter_duplicate_columns::Bool = false
end

struct PayoffResult{O <: OutcomeMatrix}
    raw::O
    filtered::O
    derived::O
end

Base.@kwdef mutable struct TinRecord{I <: Individual, P <: PayoffResult} <: Record
    id::Int = 0
    individual::I
    performance_payoffs::P
    distinction_payoffs::P
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
    distinction_score::Float64 = 0.0
end

function is_preferred(record::TinRecord, other::TinRecord)
    if record.rank < other.rank
        return true
    elseif other.rank < record.rank
        return false
    else
        if record.distinction_score > other.distinction_score
            return true
        elseif other.distinction_score > record.distinction_score
            return false
        else
            if record.individual.age < other.individual.age
                return true
            elseif other.individual.age < record.individual.age
                return false
            else
                return rand(Bool)
            end
        end
    end
end

function Base.getproperty(record::TinRecord, name::Symbol)
    if name == :raw_fitness
        return sum(record.raw_outcomes)
    elseif name == :filtered_fitness
        return sum(record.filtered_outcomes)
    elseif name == :fitness
        return sum(record.outcomes)
    end
    return getfield(record, name)
end

Base.@kwdef struct TinEvaluation{R <: TinRecord, P <: PayoffResult} <: Evaluation
    id::String
    new_parent_ids::Vector{Int}
    performance_payoffs::P
    distinction_payoffs::P
    records::Vector{R}
end