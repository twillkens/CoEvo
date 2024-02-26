module DodoLearner

export DodoLearnerEvaluator, DodoLearnerEvaluation, DodoLearnerRecord
export create_records, evaluate

import ....Interfaces: evaluate
import Base: getproperty
using ....Interfaces
using ....Abstract
using ...Criteria
using ...Matrices.Outcome
using ...Evaluators.NSGAII

Base.@kwdef struct DodoLearnerEvaluator <: Evaluator 
    id::String = "A"
    maximize::Bool = true
    max_clusters::Int = 5
    function_minimums::Union{Vector{Float64}, Nothing} = nothing
    function_maximums::Union{Vector{Float64}, Nothing} = nothing
end

Base.@kwdef mutable struct DodoLearnerRecord{I <: Individual} <: Record
    id::Int = 0
    individual::I
    raw_outcomes::Vector{Float64} = Float64[]
    outcomes::Vector{Float64} = Float64[]
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
end

function getproperty(record::DodoLearnerRecord, name::Symbol)
    if name == :fitness
        return sum(record.raw_outcomes)
    end
    return getfield(record, name)
end

Base.@kwdef struct DodoLearnerEvaluation{
    R <: DodoLearnerRecord, M1 <: OutcomeMatrix, M2 <: OutcomeMatrix
} <: Evaluation
    id::String
    parents_to_retire::Vector{Int}
    children_to_promote::Vector{Int}
    records::Vector{R}
    raw_matrix::M1
    matrix::M2
end

function create_records(
    evaluator::DodoLearnerEvaluator,
    species::AbstractSpecies,
    raw_matrix::OutcomeMatrix,
    matrix::OutcomeMatrix
)
    I = typeof(species.population[1])
    records = DodoLearnerRecord{I}[]
    for id in matrix.row_ids
        record = DodoLearnerRecord(
            id = id, 
            individual = species[id],
            raw_outcomes = raw_matrix[id, :], 
            outcomes = matrix[id, :]
        )
        push!(records, record)
    end
    criterion = evaluator.maximize ? Maximize() : Minimize()
    sorted_records = nsga_sort!(
        records, criterion, evaluator.function_minimums, evaluator.function_maximums
    )
    return sorted_records
end

using DataStructures
using ...Clusterers.GlobalKMeans: get_derived_tests
using Clustering

function get_derived_matrix(matrix::OutcomeMatrix, max_clusters::Int)
    all_columns_same = all(all(matrix.data[:, 1] .== matrix.data[:, j]) for j in 2:size(matrix.data, 2))
    all_rows_same = all(all(matrix.data[1, :] .== matrix.data[i, :]) for i in 2:size(matrix.data, 1))
    max_clusters = min(max_clusters, length(matrix.column_ids) - 1)
    
    if all_columns_same || all_rows_same || max_clusters == 1
        println("ALL_COLUMNS_SAME = ", all_columns_same)
        println("ALL_ROWS_SAME = ", all_rows_same)
        summed_column = sum(matrix.data[:, 1]) # Sum of the values in the first (and identical) column
        derived_data = fill(summed_column, (size(matrix.data, 1), 1)) # Fill a matrix with the sum
        return OutcomeMatrix("derived", matrix.row_ids, ["derived_sum"], derived_data)
    end
    X = matrix.data
    clusterings = kmeans.(Ref(X), 2:max_clusters)
    qualities = Float64[]
    for clustering in clusterings
        try 
            push!(qualities, clustering_quality(X, clustering, quality_index=:silhouettes))
        catch e
            println("clustering = ", clustering)
            throw(e)
        end
    end
    best_clustering_index = argmax(qualities)
    best_clustering = clusterings[best_clustering_index]
    centroids = best_clustering.centers
    matrix = OutcomeMatrix(
        "derived", matrix.row_ids, ["derived_$i" for i in 1:size(centroids)[2]], centroids
    )
    println("N_DERIVED_TESTS = ", length(matrix.column_ids))
    return matrix
end

using Random

function filter_raw_matrix(state::State, raw_matrix::OutcomeMatrix)
    if state.generation > 1
        other_species = state.ecosystem.all_species[2]
        hillclimber_ids = [individual.id for individual in other_species.hillclimbers]
        #children_ids = [individual.id for individual in other_species.children]
        retiree_ids = [individual.id for individual in other_species.retirees]
        #ids = [hillclimber_ids ; children_ids ; retiree_ids]
        ids = [hillclimber_ids ; retiree_ids]
        if length(hillclimber_ids) > 0
            raw_matrix = filter_columns(raw_matrix, ids)
        end
    end
    return raw_matrix
end

function get_new_children(
    parent_records::Vector{<:DodoLearnerRecord}, child_records::Vector{<:DodoLearnerRecord}
)
    parents_to_retire = Set{Int}()
    children_to_promote = Set{Int}()
    for child_record in child_records
        child_outcomes = child_record.outcomes
        for parent_record in parent_records
            if parent_record.id in parents_to_retire
                continue
            end
            parent_outcomes = parent_record.outcomes
            child_dominates_parent = dominates(Maximize(), child_outcomes, parent_outcomes)
            if child_dominates_parent
                push!(parents_to_retire, parent_record.id)
                push!(children_to_promote, child_record.id)
                break
            end
        end
    end
    return parents_to_retire, children_to_promote
end

function get_new_children(species::AbstractSpecies, records::Vector{<:DodoLearnerRecord})
    parent_records = reverse(
        [record for record in records if record.individual in species.parents]
    )
    child_records = reverse(
        [record for record in records if record.individual in species.children]
    )
    parent_outcome_sums = [sum(record.outcomes) for record in parent_records]
    child_outcome_sums = [sum(record.outcomes) for record in child_records]
    #println("PARENT_OUTCOME_SUMS = ", parent_outcome_sums)
    #println("CHILD_OUTCOME_SUMS = ", child_outcome_sums)
    parents_to_retire, children_to_promote = get_new_children(parent_records, child_records)
    return parents_to_retire, children_to_promote
end

function evaluate(
    evaluator::DodoLearnerEvaluator,
    species::AbstractSpecies,
    raw_matrix::OutcomeMatrix,
    matrix::OutcomeMatrix,
    state::State
)
    records = create_records(evaluator, species, raw_matrix, matrix)
    parents_to_retire, children_to_promote = get_new_children(species, records)
    println("NUMBER_NEW_LEARNERS = ", length(children_to_promote))
    evaluation = DodoLearnerEvaluation(
        id = species.id, 
        parents_to_retire = collect(parents_to_retire),
        children_to_promote = collect(children_to_promote),
        records = records, 
        raw_matrix = matrix, 
        matrix = matrix
    )
    return evaluation
end

function evaluate(
    evaluator::DodoLearnerEvaluator,
    species::AbstractSpecies,
    results::Vector{<:Result},
    state::State
)
    raw_matrix = OutcomeMatrix(species.population, results)
    filtered_matrix = filter_raw_matrix(state, raw_matrix)
    matrix = get_derived_matrix(filtered_matrix, evaluator.max_clusters)
    evaluation = evaluate(evaluator, species, raw_matrix, matrix, state)
    return evaluation
end

end
