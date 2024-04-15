using ....Abstract
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ...Criteria


function Base.getproperty(record::NewDodoRecord, name::Symbol)
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
    ecosystem::MaxSolveEcosystem,
    raw_matrix::OutcomeMatrix,
    filtered_matrix::OutcomeMatrix,
    matrix::OutcomeMatrix
)
    I = typeof(first(ecosystem.learner_children))
    records = NewDodoRecord{I}[]
    for id in matrix.row_ids
        record = NewDodoRecord(
            id = id, 
            individual = ecosystem[id],
            raw_outcomes = float.(raw_matrix[id, :]), 
            filtered_outcomes = float.(filtered_matrix[id, :]),
            outcomes = float.(matrix[id, :])
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

function get_high_rank_records(cluster_ids::Vector{Int}, records::Vector{<:NewDodoRecord})
    cluster_records = [record for record in records if record.id in cluster_ids]
    if length(cluster_records) != length(cluster_ids)
        println("CLUSTER_RECORDS = ", [record.id for record in cluster_records])
        println("CLUSTER_IDS = ", cluster_ids)
        error("Cluster records and cluster ids do not match")
    end
    highest_rank = first(cluster_records).rank
    high_rank_records = [record for record in cluster_records if record.rank == highest_rank]
    return high_rank_records
end


function get_cluster_leader_id(
    cluster_ids::Vector{Int}, records::Vector{<:NewDodoRecord}
)
    high_rank_records = get_high_rank_records(cluster_ids, records)
    #parent_records = [
    #    record for record in high_rank_records if record.individual in species.parents
    #]
    #other_records = [record for record in high_rank_records if !(record in parent_records)]
    #chosen_record = length(other_records) > 0 ? rand(other_records) : rand(parent_records)
    chosen_record = rand(high_rank_records)
    id = chosen_record.id
    return id
end

function get_cluster_leader_ids(
    all_cluster_ids::Vector{Vector{Int}}, 
    records::Vector{<:NewDodoRecord}
)
    leader_ids = [
        get_cluster_leader_id(cluster_ids, records) for cluster_ids in all_cluster_ids
    ]
    return leader_ids
end

function print_info(
    #evaluator::NewDodoEvaluator, 
    raw_matrix::OutcomeMatrix, 
    filtered_matrix::OutcomeMatrix, 
    derived_matrix::OutcomeMatrix, 
    records::Vector{<:NewDodoRecord}, 
    all_cluster_ids::Vector{Vector{Int}}
)
    #println("--------EVALUATOR_$(evaluator.id)-----")
    println("CLUSTER_SIZES = ", [length(cluster) for cluster in all_cluster_ids])
    println("SIZE_RAW_MATRIX = ", size(raw_matrix.data))
    println("SIZE_FILTERED_MATRIX = ", size(filtered_matrix.data))
    println("SIZE_DERIVED_MATRIX = ", size(derived_matrix.data))
    #tag = evaluator.objective == "performance" ? "FILTERED_OUTCOMES" : "FILTERED_DISTINCTIONS"
    tag = "SUM_OUTCOMES"
    println("$tag = ", [Int(sum(record.raw_outcomes)) for record in records])
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