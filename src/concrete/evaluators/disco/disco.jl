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
    id::String = "A"
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
using Clustering


function get_derived_matrix(
    rng::AbstractRNG,
    matrix::OutcomeMatrix,
    max_clusters::Int = 5,
    distance_method::String = "euclidean"
)
    indiv_tests = SortedDict{Int, Vector{Float64}}(id => float.(matrix[id, :]) for id in matrix.row_ids)
    derived_tests = get_derived_tests(rng, indiv_tests, max_clusters, distance_method)
    n_derived_tests = length(first(collect(values(derived_tests))))
    derived_data = zeros(Float64, length(matrix.row_ids), n_derived_tests)
    for (i, derived_test) in enumerate(values(derived_tests))
        derived_data[i, :] = derived_test
    end
    derived_matrix = OutcomeMatrix(
        "derived", matrix.row_ids, collect(1:n_derived_tests), derived_data
    )
    println("N_DERIVED_TESTS = ", n_derived_tests)
    return derived_matrix
end

function get_derived_matrix(matrix::OutcomeMatrix, max_clusters::Int)
    all_columns_same = all(all(matrix.data[:, 1] .== matrix.data[:, j]) for j in 2:size(matrix.data, 2))
    all_rows_same = all(all(matrix.data[1, :] .== matrix.data[i, :]) for i in 2:size(matrix.data, 1))
    max_clusters = min(max_clusters, length(matrix.column_ids) - 1)
    
    if all_columns_same || all_rows_same || max_clusters == 1
        println("ALL_COLUMNS_SAME = ", all_columns_same)
        println("ALL_ROWS_SAME = ", all_rows_same)
        println("LENGTH_MAX_CLUSTERS = ", length(max_clusters))
        # If all columns are the same, return a matrix with a single column where each row is the sum of a single column
        summed_column = sum(matrix.data[:, 1]) # Sum of the values in the first (and identical) column
        derived_data = fill(summed_column, (size(matrix.data, 1), 1)) # Fill a matrix with the sum
        # Update to create a new OutcomeMatrix with a single "derived" column
        println("NOTHING")
        return OutcomeMatrix("derived", matrix.row_ids, ["derived_sum"], derived_data)
    end
    println("MAX CLUSTERS: ", max_clusters)
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

const USE_NSGAII = false
using Random

function evaluate(
    evaluator::DiscoEvaluator,
    species::AbstractSpecies,
    raw_matrix::OutcomeMatrix,
    state::State
)
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
    #raw_matrix = filter_identical_columns(raw_matrix)
    #matrix = get_derived_matrix(
    #    state.rng, raw_matrix, evaluator.max_clusters, evaluator.distance_method
    #)
    matrix = get_derived_matrix(raw_matrix, evaluator.max_clusters)
    #println("N_OTHERS =", length(matrix.row_ids))
    if USE_NSGAII
        records = create_records(evaluator, species, raw_matrix, matrix)
    else
        all_ids = sort([individual.id for individual in species.population])
        parent_ids = all_ids[1:50]
        child_ids = all_ids[51:end]
        shuffle!(state.rng, parent_ids)
        shuffle!(state.rng, child_ids)
        parents_to_replace = Set{Int}()
        children_to_promote = Set{Int}()
        time_start = time()
        for child_id in child_ids
            for parent_id in parent_ids
                if parent_id in parents_to_replace
                    continue
                end
                child_outcomes = matrix[child_id, :]
                parent_outcomes = matrix[parent_id, :]
                child_dominates_parent = dominates(Maximize(), child_outcomes, parent_outcomes)
                if child_dominates_parent
                    push!(parents_to_replace, parent_id)
                    push!(children_to_promote, child_id)
                    break
                end
            end
        end
        time_end = time()
        println("TIME = ", time_end - time_start)
        new_parent_ids = [id for id in parent_ids if !(id in parents_to_replace) ]
        population_ids = [new_parent_ids ; collect(children_to_promote)]
        if length(population_ids) != length(parent_ids)
            error("Population size is $(length(population_ids)), but should be $(length(parent_ids))")
        end
        raw_matrix = filter_rows(raw_matrix, population_ids)
        matrix = filter_rows(matrix, population_ids)
        records = create_records(evaluator, species, raw_matrix, matrix)
        println("NUMBER_NEW_LEARNERS = ", length(children_to_promote))
    end
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
        raw_matrix = OutcomeMatrix(species.population, results)
    elseif evaluator.objective == "distinctions"
        raw_matrix = make_distinction_matrix(species.population, results)
    else
        error("Objective must be either 'performance' or 'distinctions'")
    end
    evaluation = evaluate(evaluator, species, raw_matrix, state)
    return evaluation
end

end
