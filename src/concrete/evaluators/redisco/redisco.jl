module Redisco

export RediscoEvaluator, RediscoEvaluation, evaluate, get_cluster_ids, get_hillclimber_id

import ....Interfaces: evaluate
using ...Clusterers.GlobalKMeans
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ....Abstract
using ....Interfaces
using ...Criteria

Base.@kwdef struct RediscoEvaluator <: Evaluator
    id::String = "A"
    max_clusters::Int = 5
end

Base.@kwdef struct RediscoEvaluation <: Evaluation
    id::String
    hillclimber_ids::Vector{Int}
    matrix::OutcomeMatrix
    clustering_result::KMeansClusteringResult
    cluster_records::Vector{Vector{NSGAIIRecord}}
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

function get_hillclimber_id(
    cluster_ids::Vector{Int}, hillclimber_ids::Vector{Int}, matrix::OutcomeMatrix, state::State
)
    records = [NSGAIIRecord(id = id, outcomes = matrix[id, :]) for id in cluster_ids]
    nsga_sort!(records, Maximize())
    # the criteria for usurping a hillclimber is if an explorer/child in the cluster strictly 
    # dominates the hillclimber with respect to distinctions
    rank_one_ids = [record.id for record in records if record.rank == 1]
    rank_one_hillclimber_ids = intersect(rank_one_ids, hillclimber_ids)
    hillclimber_id = length(rank_one_hillclimber_ids) > 0 ? 
        rand(state.rng, rank_one_hillclimber_ids) : rand(state.rng, rank_one_ids)
    return hillclimber_id, records
end

using Serialization

function evaluate(
    evaluator::RediscoEvaluator, 
    hillclimber_ids::Vector{Int},
    matrix::OutcomeMatrix,
    state::State
)
    matrix = filter_zero_rows(matrix)
    new_hillclimber_ids = Int[]
    clustering_result = KMeansClusteringResult()
    cluster_records = Vector{Vector{NSGAIIRecord}}()

    # if no distinctions have been found then continue
    if length(matrix.row_ids) == 1
        push!(new_hillclimber_ids, first(matrix.row_ids))
    elseif length(matrix.row_ids) > 0
        try
            clustering_result = get_fast_global_clustering_result(
                state.rng, matrix.data, max_clusters = evaluator.max_clusters
            )
            all_cluster_ids = get_cluster_ids(clustering_result, matrix)

            for cluster_ids in all_cluster_ids
                hillclimber_id, records = get_hillclimber_id(
                    cluster_ids, hillclimber_ids, matrix, state
                )
                push!(new_hillclimber_ids, hillclimber_id)
                push!(cluster_records, records)
            end
        catch e
            println("matrix = $matrix")
            serialize("test/redisco/matrix.jls", matrix)
            throw(e)
        end
    end
    evaluation = RediscoEvaluation(
        id = evaluator.id,
        hillclimber_ids = new_hillclimber_ids,
        matrix = matrix,
        clustering_result = clustering_result,
        cluster_records = cluster_records
    )
    return evaluation
end

function evaluate(
    evaluator::RediscoEvaluator, 
    species::AbstractSpecies,
    results::Vector{<:Result},
    state::State
)
    matrix = make_distinction_matrix(species.population, results)
    hillclimber_ids = [individual.id for individual in species.hillclimbers]
    evaluation = evaluate(evaluator, hillclimber_ids, matrix, state)
    return evaluation
end

end