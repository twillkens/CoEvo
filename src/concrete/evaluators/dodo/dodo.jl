module Dodo

export DodoEvaluator, DodoEvaluation, evaluate
export get_cluster_ids, child_dominates_parent

import ....Interfaces: evaluate
#using ...Clusterers.XMeans: multiple_xmeans, KMeansClusteringResult, x_means_nosplits, do_kmeans
using Clustering
#using ...Clusterers.GlobalKMeans: get_fast_global_clustering_result, KMeansClusteringResult
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ....Abstract
using ....Interfaces
using ...Criteria

Base.@kwdef struct DodoEvaluator <: Evaluator
    id::String = "A"
    min_clusters::Int = 1
    max_clusters::Int = 5
    n_runs::Int = 10
end

Base.@kwdef struct DodoEvaluation <: Evaluation
    id::String
    explorer_to_promote_ids::Vector{Int}
    children_to_promote_ids::Vector{Int}
    hillclimbers_to_demote_ids::Vector{Int}
    matrix::OutcomeMatrix
end


function child_dominates_parent(child::Individual, matrix::OutcomeMatrix)
    #println("row_ids = ", matrix.row_ids)
    #println("child.id = ", child.id)
    #println("child.parent_id = ", child.parent_id)
    if !(child.parent_id in matrix.row_ids)
        return true
    end
    parent_outcomes = matrix[child.parent_id, :]
    child_outcomes = matrix[child.id, :]
    child_dominates_parent = dominates(Maximize(), child_outcomes, parent_outcomes)
    return child_dominates_parent
end

function get_dominant_children(species, matrix, cluster_ids)
    all_child_ids = [child.id for child in species.children]
    child_ids = [id for id in cluster_ids if id in all_child_ids]
    children = [child for child in species.children if child.id in child_ids]
    dominant_children = [
        child for child in children if child_dominates_parent(child, matrix)
    ]
    return dominant_children
end

function perform_kmeans_search(matrix::OutcomeMatrix, max_clusters::Int)
    if length(matrix.row_ids) == 0
        return []
    elseif length(matrix.row_ids) == 1
        return [[first(matrix.row_ids)]]
    elseif length(matrix.row_ids) == 2
        id_1, id_2 = matrix.row_ids
        if matrix[id_1, :] == matrix[id_2, :]
            return [[id_1, id_2]]
        else
            return [[id_1], [id_2]]
        end
    else
        max_clusters = min(max_clusters, length(matrix.row_ids) - 1)
        X = transpose(matrix.data)
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
        clustering_dict = Dict{Int, Vector{Int}}()
        for (row_index, assignment) in enumerate(best_clustering.assignments)
            if haskey(clustering_dict, assignment)
                push!(clustering_dict[assignment], matrix.row_ids[row_index])
            else
                clustering_dict[assignment] = [matrix.row_ids[row_index]]
            end
        end
        cluster_ids = collect(values(clustering_dict))
        return cluster_ids
    end
end
function evaluate(
    evaluator::DodoEvaluator, 
    species::AbstractSpecies,
    results::Vector{<:Result},
    state::State
)
    matrix = make_distinction_matrix(species.population, results)
    matrix = filter_zero_rows(matrix)
    matrix = filter_identical_columns(matrix)
    if length(matrix.row_ids) == 0
        return DodoEvaluation(
            id = evaluator.id, 
            explorer_to_promote_ids = Int[], 
            children_to_promote_ids = Int[], 
            hillclimbers_to_demote_ids = Int[], 
            matrix = matrix,
        )
    end
    n_clusters = min(evaluator.max_clusters, length(matrix.row_ids))
    #clustering_result = do_kmeans(matrix.data, n_clusters, state.rng)

    #all_cluster_ids = get_cluster_ids(clustering_result, matrix)
    all_cluster_ids = perform_kmeans_search(matrix, n_clusters)
    all_explorer_ids = [explorer.id for explorer in species.explorers]
    all_parent_ids = [parent.id for parent in species.hillclimbers]
    explorer_to_promote_ids = Int[]
    children_to_promote_ids = Int[] 
    hillclimbers_to_demote_ids = Int[]
    println("N_CLUSTERS = ", length(all_cluster_ids))
    println("all_cluster_ids = ", all_cluster_ids)

    for cluster_ids in all_cluster_ids
        info = []
        for id in cluster_ids
            individual = species[id]
            max_dimension = argmax(individual.genotype.genes)
            v = round(individual.genotype.genes[max_dimension], digits=2)
            i = (max_dimension, v)

            push!(info, i)
        end
        sort!(info, by = x -> x[1])
        println("cluster_info = ", info)
        all_are_explorers = all(id -> id in all_explorer_ids, cluster_ids)
        if all_are_explorers
            println("all_are_explorers = ", cluster_ids)
            push!(explorer_to_promote_ids, rand(state.rng, cluster_ids))
        else
            dominant_children = get_dominant_children(species, matrix, cluster_ids)
            if length(dominant_children) > 0
                child_to_promote = rand(state.rng, dominant_children)
                push!(children_to_promote_ids, child_to_promote.id)
                other_hillclimber_ids = [
                    id for id in all_parent_ids 
                        if id in cluster_ids && id != child_to_promote.parent_id
                ]
                #append!(hillclimbers_to_demote_ids, other_hillclimber_ids)
                println("child_to_promote = ", child_to_promote.id)
                println("to_demote = ", other_hillclimber_ids)
            end
        end
    end

    evaluation = DodoEvaluation(
        id = evaluator.id, 
        explorer_to_promote_ids = explorer_to_promote_ids, 
        children_to_promote_ids = children_to_promote_ids, 
        hillclimbers_to_demote_ids = hillclimbers_to_demote_ids,
        matrix = matrix,
    )
    return evaluation
end

end
#function get_cluster_ids(result::KMeansClusteringResult, matrix::OutcomeMatrix)
#    all_cluster_ids = Vector{Vector{Int}}()
#    for indices in result.cluster_indices
#        cluster_ids = Int[]
#        for index in indices
#            push!(cluster_ids, matrix.row_ids[index])
#        end
#        push!(all_cluster_ids, cluster_ids)
#    end
#    return all_cluster_ids
#end