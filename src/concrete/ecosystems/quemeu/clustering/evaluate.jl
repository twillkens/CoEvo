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
    ecosystem::QueMEUEcosystem,
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
