using ....Abstract
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ...Criteria

function create_records(
    evaluator::DodoTestEvaluator,
    species::AbstractSpecies,
    raw_matrix::OutcomeMatrix,
    matrix::OutcomeMatrix
)
    I = typeof(species.population[1])
    records = DodoTestRecord{I}[]
    for id in matrix.row_ids
        record = DodoTestRecord(
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

function evaluate(
    evaluator::DodoTestEvaluator, 
    species::AbstractSpecies,
    results::Vector{<:Result},
    state::State
)
    #if state.generation > 1
	   # elite_records = state.evaluations[1].records[1:50]
	   # elite_ids = [record.id for record in elite_records]
	   # results = [result for result in results if first(result.match.individual_ids) in elite_ids]
    #end
    raw_matrix = make_distinction_matrix(species.population, results)
    matrix, all_cluster_ids = perform_clustering(evaluator, raw_matrix)
    records = create_records(evaluator, species, raw_matrix, matrix)
    promotions = DodoPromotions(species, records, all_cluster_ids)

    evaluation = DodoTestEvaluation(
        id = evaluator.id, 
        promotions = promotions,
        raw_matrix = raw_matrix,
        matrix = matrix,
        records = records
    )
    return evaluation
end