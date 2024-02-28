using ....Abstract
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ...Criteria

function create_records(
    evaluator::SpreadDodoEvaluator,
    species::AbstractSpecies,
    raw_matrix::OutcomeMatrix,
    filtered_matrix::OutcomeMatrix,
    matrix::OutcomeMatrix
)
    I = typeof(species.population[1])
    records = SpreadDodoRecord{I}[]
    for id in matrix.row_ids
        record = SpreadDodoRecord(
            id = id, 
            individual = species[id],
            raw_outcomes = raw_matrix[id, :], 
            filtered_outcomes = filtered_matrix[id, :],
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

function evaluate(
    evaluator::SpreadDodoEvaluator, 
    species::AbstractSpecies,
    results::Vector{<:Result},
    state::State
)
    #if state.generation > 1
    #    other_species = state.ecosystem.all_species[1]
    #    parent_ids = [individual.id for individual in other_species.parents]
	   # results = [result for result in results if first(result.match.individual_ids) in parent_ids]
    #end
    raw_matrix = make_distinction_matrix(species.population, results)
    filtered_matrix, matrix, all_cluster_ids = perform_clustering(evaluator, raw_matrix)
    println("--------TEST_EVALATOR-----")
    println("CLUSTER_SIZES = ", [length(cluster) for cluster in all_cluster_ids])
    println("SIZE_TEST_RAW_MATRIX = ", size(raw_matrix.data))
    println("SIZE_TEST_MATRIX = ", size(matrix.data))
    records = create_records(evaluator, species, raw_matrix, filtered_matrix, matrix)
    println("FILTERED_DISTINCTIONS = ", [sum(record.filtered_outcomes) for record in records])
    cluster_leaders = Int[]
    for cluster_ids in all_cluster_ids
        cluster_records = [record for record in records if record.id in cluster_ids]
        chosen_record = first(cluster_records)
        push!(cluster_leaders, chosen_record.id)
    end

    evaluation = SpreadDodoEvaluation(
        id = evaluator.id, 
        cluster_leaders = cluster_leaders,
        raw_matrix = raw_matrix,
        filtered_matrix = filtered_matrix,
        matrix = matrix,
        records = records
    )
    return evaluation
end