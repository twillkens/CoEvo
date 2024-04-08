using ....Abstract
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ...Criteria


function Base.getproperty(record::DiscoRecord, name::Symbol)
    if name == :raw_fitness
        return sum(record.raw_outcomes)
    elseif name == :filtered_fitness
        return sum(record.filtered_outcomes)
    elseif name == :fitness
        return sum(record.outcomes)
    end
    return getfield(record, name)
end

function create_records(
    raw_matrix::OutcomeMatrix, filtered_matrix::OutcomeMatrix, matrix::OutcomeMatrix,
    ids_cluster_map::Dict{Int, Int}
)
    records = DiscoRecord[]
    for id in matrix.row_ids
        record = DiscoRecord(
            id = id, 
            raw_outcomes = float.(raw_matrix[id, :]), 
            filtered_outcomes = float.(filtered_matrix[id, :]),
            outcomes = float.(matrix[id, :]),
            cluster = ids_cluster_map[id]
        )
        push!(records, record)
    end
    criterion = Maximize()
    sorted_records = nsga_sort!(records, criterion, nothing, nothing)
    return sorted_records
end

function reconstruct_matrix(raw_matrix::OutcomeMatrix, filtered_matrix::OutcomeMatrix)
    filtered_data = zeros(Float64, length(raw_matrix.row_ids), length(filtered_matrix.column_ids))
    for (row_index, id) in enumerate(raw_matrix.row_ids)
        if id in filtered_matrix.row_ids
            filtered_data[row_index, :] = filtered_matrix[id, :]
        end
    end
    filtered_matrix = OutcomeMatrix(
        raw_matrix.id, raw_matrix.row_ids, filtered_matrix.column_ids, filtered_data
    )
    return filtered_matrix
end

function print_info(
    #evaluator::NewDodoEvaluator, 
    raw_matrix::OutcomeMatrix, 
    filtered_matrix::OutcomeMatrix, 
    derived_matrix::OutcomeMatrix, 
    records::Vector{<:DiscoRecord}, 
    all_cluster_ids::Vector{Vector{Int}}
)
    #println("--------EVALUATOR_$(evaluator.id)-----")
    println("CLUSTER_SIZES = ", [length(cluster) for cluster in all_cluster_ids])
    println("SIZE_RAW_MATRIX = ", size(raw_matrix.data))
    tag = "SUM_RAW_OUTCOMES"
    println("$tag = ", sort([Int(sum(record.raw_outcomes)) for record in records]; rev=true))
    println("SIZE_FILTERED_MATRIX = ", size(filtered_matrix.data))
    tag = "SUM_FILTERED_OUTCOMES_"
    println("$tag = ", sort([Int(sum(record.filtered_outcomes)) for record in records]; rev=true))
    println("SIZE_DERIVED_MATRIX = ", size(derived_matrix.data))
end

function evaluate_disco(raw_matrix::OutcomeMatrix, species_id::String, state::State)
    #results = filter_results_by_cohort(evaluator, species, results, state)
    #println("RAW_MATRIX = ", raw_matrix)
    filtered_matrix = get_filtered_matrix(raw_matrix; rng = state.rng)
    #println("FILTERED_MATRIX_IDS = ", filtered_matrix.row_ids)
    #println("SIZE_FILTERED_MATRIX = ", size(filtered_matrix.data))
    #println("SUM_FILTERED_OUTCOMES = ", [Int(sum(filtered_matrix[id, :])) for id in filtered_matrix.row_ids])
    #println("FILTERED_MATRIX = ", filtered_matrix)
    #filtered_matrix = deepcopy(raw_matrix)
    derived_matrix, all_cluster_ids = get_derived_matrix(filtered_matrix)
    #println("DERIVED_MATRIX_IDS = ", derived_matrix.row_ids)
    if length(all_cluster_ids) == 0
        all_cluster_ids = [[id for id in raw_matrix.row_ids]]
    end
    ids_cluster_map = create_row_id_to_cluster_id_map(all_cluster_ids)
    #println("DERIVED_MATRIX = ", derived_matrix)
    #println("ALL_CLUSTER_IDS = ", all_cluster_ids)
    #println("IDS_CLUSTER_MAP = ", ids_cluster_map)
    reconstructed_filtered_matrix = reconstruct_matrix(raw_matrix, filtered_matrix)
    reconstructed_derived_matrix = reconstruct_matrix(raw_matrix, derived_matrix)
    records = create_records(
        raw_matrix, reconstructed_filtered_matrix, reconstructed_derived_matrix, ids_cluster_map
    )
    println("DISCO_RECORDS_$(species_id) = ", [
        (record.rank, round(record.crowding; digits=2)) 
        for record in records]
    )

    evaluation = DiscoEvaluation(
        id = species_id,
        raw_matrix = raw_matrix,
        filtered_matrix = reconstructed_filtered_matrix,
        matrix = reconstructed_derived_matrix,
        records = records
    )
    print_info(raw_matrix, filtered_matrix, derived_matrix, records, all_cluster_ids)
    return evaluation
    #return new_parent_ids
end

# function get_other_species(species::AbstractSpecies, state::State)
#     other_species = first(
#         filter(other_species -> other_species.id != species.id, state.ecosystem.all_species)
#     )
#     return other_species
# end
# 
# function get_cohort_ids(species::AbstractSpecies, cohort_string::String)
#     cohort_symbol = Symbol(cohort_string)
#     cohort = getfield(species, cohort_symbol)
#     ids = Set([individual.id for individual in cohort])
#     return ids
# end
# 
# function filter_results_by_cohort(
#     evaluator::NewDodoEvaluator, 
#     species::AbstractSpecies, 
#     results::Vector{R}, 
#     state::State
# ) where R <: Result
#     if state.generation == 1
#         return results
#     end
#     filtered_results = R[]
#     other_species = get_other_species(species, state)
#     ids_to_use = Set{Int}()
#     for cohort_string in evaluator.other_species_comparison_cohorts
#         cohort_ids = get_cohort_ids(other_species, cohort_string)
#         union!(ids_to_use, cohort_ids)
#     end
# 
#     for result in results
#         individual_ids = result.match.individual_ids
#         if any(id in ids_to_use for id in individual_ids)
#             push!(filtered_results, result)
#         end
#     end
#     return filtered_results
# end



#function get_hillclimber_parent_ids(species::AbstractSpecies, matrix::OutcomeMatrix)
#    new_parent_ids = Int[]
#    for child in species.children
#        parent = species[child.parent_id]
#        child_outcomes = matrix[child.id, :]
#        parent_outcomes = matrix[parent.id, :]
#        parent_dominates_child = dominates(Maximize(), parent_outcomes, child_outcomes)
#        if parent_dominates_child
#            push!(new_parent_ids, parent.id)
#        else
#            child_on_lower_level = sum(child_outcomes) < sum(parent_outcomes)
#            if child_on_lower_level
#                push!(new_parent_ids, parent.id)
#            else
#                push!(new_parent_ids, child.id)
#            end
#        end
#    end
#    return new_parent_ids
#end