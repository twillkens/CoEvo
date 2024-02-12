module HillClimber

export HillClimberEvaluator, HillClimberEvaluation, evaluate

import ....Interfaces: evaluate
using ...Clusterers.GlobalKMeans
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ....Abstract
using ....Interfaces
using ...Criteria

Base.@kwdef struct HillClimberEvaluator <: Evaluator
    id::String = "A"
    max_clusters::Int = 5
end

Base.@kwdef struct HillClimberEvaluation <: Evaluation
    id::String
    to_promote_ids::Vector{Int}
    to_defer_ids::Vector{Int}
    matrix::OutcomeMatrix
end

function get_cluster_ids(result::KMeansClusteringResult, matrix::OutcomeMatrix)
    all_cluster_ids = Vector{Vector{Int}}()
    for indices in result.cluster_indices
        cluster_ids = Int[]
        for index in indices
            push!(cluster_ids, matrix.row_ids[index])
        end
        push!(all_cluster_ids, cluster_ids)
    end
    return all_cluster_ids
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

function evaluate(
    evaluator::HillClimberEvaluator, 
    species::AbstractSpecies,
    results::Vector{<:Result},
    state::State
)
    matrix = make_distinction_matrix(species.population, results)
    matrix = filter_zero_rows(matrix)
    matrix = filter_identical_columns(matrix)
    clustering_result = get_fast_global_clustering_result(
        state.rng, matrix.data, max_clusters = evaluator.max_clusters
    )
    all_cluster_ids = get_cluster_ids(clustering_result, matrix)
    all_child_ids = [child.id for child in species.children]
    to_promote_ids = Int[]
    to_defer_ids = Int[]

    for cluster_ids in all_cluster_ids
        child_ids = [id for id in cluster_ids if id in all_child_ids]
        children = [child for child in species.children if child.id in child_ids]
        dominant_children = [
            child for child in children if child_dominates_parent(child, matrix)
        ]
        if length(dominant_children) > 0
            preferred_ids = [child.id for child in dominant_children if child.id in species.preferred]
            nonpreferred_ids = setdiff(child_ids, preferred_ids)
            chosen_id = length(preferred_ids) > 0 ? 
                rand(state.rng, preferred_ids) : rand(state.rng, nonpreferred_ids)
            push!(to_promote_ids, chosen_id)
            push!(to_defer_ids, species[chosen_id].parent_id)
            for child_id in child_ids
                if child_id != chosen_id
                    push!(to_defer_ids, species[child_id].parent_id)
                    push!(to_defer_ids, child_id)
                end
            end
        end
    end

    evaluation = HillClimberEvaluation(
        id = evaluator.id, 
        to_promote_ids = to_promote_ids, 
        to_defer_ids = to_defer_ids, 
        matrix = matrix,
    )
    return evaluation
end

#function evaluate(
#    evaluator::HillClimberEvaluator, 
#    species::AbstractSpecies,
#    results::Vector{<:Result},
#    ::State
#)
#    matrix = make_distinction_matrix(species.population, results)
#    println("row_ids = ", matrix.row_ids)
#
#    winner_ids = Int[]
#    for (parent, child) in zip(species.parents, species.children)
#        parent_outcomes = matrix[parent.id, :]
#        child_outcomes = matrix[child.id, :]
#        winner_id = dominates(Maximize(), child_outcomes, parent_outcomes) ? child.id : parent.id
#        push!(winner_ids, winner_id)
#    end
#
#    evaluation = HillClimberEvaluation(
#        id = evaluator.id, winner_ids = winner_ids, matrix = matrix,
#    )
#    return evaluation
#end

end