module Dodo

export DodoEvaluator, DodoEvaluation, evaluate
export child_dominates_parent

import ....Interfaces: evaluate
#using ...Clusterers.XMeans: multiple_xmeans, KMeansClusteringResult, x_means_nosplits, do_kmeans
using Clustering
#using ...Clusterers.GlobalKMeans: get_fast_global_clustering_result, KMeansClusteringResult
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ....Abstract
using ....Interfaces
using ...Criteria

include("matrix.jl")

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
    #return sum(child_outcomes) > sum(parent_outcomes)
    child_dominates_parent = dominates(Maximize(), child_outcomes, parent_outcomes)
    #child_dominates_parent = is_nondominated(child_outcomes, parent_outcomes)
    return child_dominates_parent
end

function get_dominant_children(species, matrix, cluster_ids, claimed_parents)
    all_child_ids = [child.id for child in species.children if !(child.parent_id in claimed_parents)]
    child_ids = [id for id in cluster_ids if id in all_child_ids]
    children = [child for child in species.children if child.id in child_ids]
    dominant_children = [
        child for child in children if child_dominates_parent(child, matrix)
    ]
    return dominant_children
end


function evaluate(
    evaluator::DodoEvaluator, 
    species::AbstractSpecies,
    results::Vector{<:Result},
    state::State
)
    matrix = make_distinction_matrix(species.population, results)
    orig_matrix = deepcopy(matrix)
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
    #all_cluster_ids = perform_kmeans_search(matrix, n_clusters)
    matrix, all_cluster_ids = perform_kmeans_and_get_derived_matrix(matrix, n_clusters)
    all_explorer_ids = [explorer.id for explorer in species.explorers]
    all_retiree_ids = [retiree.id for retiree in species.retirees]
    append!(all_explorer_ids, all_retiree_ids)
    all_parent_ids = [parent.id for parent in species.hillclimbers]
    explorer_to_promote_ids = Int[]
    children_to_promote_ids = Int[] 
    hillclimbers_to_demote_ids = Int[]
    println("N_CLUSTERS = ", length(all_cluster_ids))
    #println("all_cluster_ids = ", all_cluster_ids)
    claimed_parents = Set{Int}()

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
        #println("cluster_info = ", info)
        all_are_explorers = all(id -> id in all_explorer_ids, cluster_ids)
        if all_are_explorers
            println("ALL_ARE_EXPLORERS = ", cluster_ids)
            push!(explorer_to_promote_ids, rand(state.rng, cluster_ids))
        else
            dominant_children = get_dominant_children(species, matrix, cluster_ids, claimed_parents)
            if length(dominant_children) > 0
                child_to_promote = rand(state.rng, dominant_children)
                push!(claimed_parents, child_to_promote.parent_id)
                push!(children_to_promote_ids, child_to_promote.id)
                other_hillclimber_ids = [
                    id for id in all_parent_ids 
                        if id in cluster_ids && id != child_to_promote.parent_id
                ]
                #append!(hillclimbers_to_demote_ids, other_hillclimber_ids)
                println("CHILD_TO_PROMOTE = ", child_to_promote.id)
            end
        end
    end

    outcomes = []
    for (hc, child) in zip(species.hillclimbers, species.children)
        n_hc_outcomes = sum(orig_matrix[hc.id, :])
        n_child_outcomes = sum(orig_matrix[child.id, :])
        push!(outcomes, (n_hc_outcomes, n_child_outcomes))
    end
    println("n_outcomes = ", outcomes)

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