module Outcome

export OutcomeMatrix, make_distinction_matrix, filter_zero_rows, get_sorted_dict
export generate_unique_tuples

import Base: getindex
using DataStructures
using ....Abstract

struct OutcomeMatrix{T, U, V}
    id::T
    row_ids::Vector{U}
    column_ids::Vector{V}
    data::Matrix{Float64}
end

# Get a row by row_id, accommodating idiosyncratic IDs
function getindex(matrix::OutcomeMatrix, row_id::Any)
    row_index = findfirst(==(row_id), matrix.row_ids)
    if row_index === nothing
        throw(ArgumentError("Row ID $row_id not found"))
    end
    return matrix.data[row_index, :]
end

function getindex(matrix::OutcomeMatrix, row_id::Any, ::Colon)
    row_index = findfirst(==(row_id), matrix.row_ids)
    if row_index === nothing
        throw(ArgumentError("Row ID $row_id not found"))
    end
    return matrix.data[row_index, :]
end
# Get a column by column_id, accommodating idiosyncratic IDs
function getindex(matrix::OutcomeMatrix, ::Colon, column_id::Any)
    column_index = findfirst(==(column_id), matrix.column_ids)
    if column_index === nothing
        throw(ArgumentError("Column ID $column_id not found"))
    end
    return matrix.data[:, column_index]
end

# Get a cell value by [row_id, column_id], accommodating idiosyncratic IDs
function getindex(matrix::OutcomeMatrix, row_id, column_id)
    row_index = findfirst(==(row_id), matrix.row_ids)
    column_index = findfirst(==(column_id), matrix.column_ids)
    if row_index === nothing || column_index === nothing
        throw(ArgumentError("Invalid row ID $row_id or column ID $column_id"))
    end
    return matrix.data[row_index, column_index]
end

function OutcomeMatrix(data::Matrix{Float64})
    id = 0
    row_ids = collect(1:size(data, 1))
    # make column ids start at n_row_ids + 1
    column_ids = collect(size(data, 1) + 1:size(data, 1) + size(data, 2))
    return OutcomeMatrix(id, row_ids, column_ids, data)
end

function OutcomeMatrix(
    row_ids::Vector{Int}, column_ids::Vector{Int}, results::Vector{<:Result}; rev::Bool = false
)
    row_dict = Dict(id => i for (i, id) in enumerate(row_ids))
    column_dict = Dict(id => i for (i, id) in enumerate(column_ids))
    data = zeros(Float64, length(row_ids), length(column_ids))
    n_processed = 0
    for result in results
        id_1, id_2 = result.match.individual_ids
        outcome_1, outcome_2 = result.outcome_set
        if id_1 in keys(row_dict) && id_2 in keys(column_dict)
            row = row_dict[id_1]
            column = column_dict[id_2]
            data[row, column] = rev ? outcome_2 : outcome_1
            n_processed += 1
        elseif id_2 in keys(row_dict) && id_1 in keys(column_dict)
            row = row_dict[id_2]
            column = column_dict[id_1]
            data[row, column] = rev ? outcome_1 : outcome_2
            n_processed += 1
        end
    end
    if n_processed != length(data)
        error("Not all results were processed")
    end
    matrix = OutcomeMatrix("outcome", row_ids, column_ids, data)
    return matrix
end

function OutcomeMatrix(row_ids::Vector{Int}, results::Vector{<:Result}; rev::Bool = false)
    # Assume existence of a Set or Dictionary to track unique column IDs per row ID
    unique_column_ids = Set{Int}()

    # Populate unique_column_ids based on results
    for result in results
        id_1, id_2 = result.match.individual_ids
        if id_1 in row_ids
            push!(unique_column_ids, id_2)
        end
        if id_2 in row_ids
            push!(unique_column_ids, id_1)
        end
    end

    # Convert Set to sorted Vector and ensure row_ids is sorted
    sorted_column_ids = sort(collect(unique_column_ids))
    sorted_row_ids = sort(row_ids)

    # Now call the original OutcomeMatrix method with the sorted and prepared IDs
    matrix = OutcomeMatrix(sorted_row_ids, sorted_column_ids, results; rev=rev)
    return matrix
end

function OutcomeMatrix(
    individuals::Vector{<:Individual}, results::Vector{<:Result}; rev::Bool = false
)
    row_ids = [individual.id for individual in individuals]
    matrix = OutcomeMatrix(row_ids, results; rev=rev)
    return matrix
end

function generate_unique_tuples(ids::Vector{T}) where T
    n = length(ids)
    unique_tuples = [(ids[i], ids[j]) for i in 1:n for j in (i+1):n]
    return unique_tuples
end

function make_distinction_matrix(matrix::OutcomeMatrix)
    column_pairs = generate_unique_tuples(matrix.column_ids)
    data = zeros(Float64, length(matrix.row_ids), length(column_pairs))
    for i in eachindex(matrix.row_ids)
        for (j, (id_1, id_2)) in enumerate(column_pairs)
            row_id = matrix.row_ids[i]
            data[i, j] = matrix[row_id, id_1] != matrix[row_id, id_2] ? 1.0 : 0.0
        end
    end
    matrix = OutcomeMatrix(matrix.id, matrix.row_ids, column_pairs, data)
    return matrix
end

function make_distinction_matrix(matrix::Matrix{Float64})
    matrix = OutcomeMatrix(matrix)
    distinction_matrix = make_distinction_matrix(matrix)
    return distinction_matrix
end

function make_distinction_matrix(row_ids::Vector{Int}, column_ids::Vector{Int}, results::Vector{<:Result})
    matrix = OutcomeMatrix(row_ids, column_ids, results; rev = true)
    distinction_matrix = make_distinction_matrix(matrix)
    return distinction_matrix
end

function make_distinction_matrix(row_ids::Vector{Int}, results::Vector{<:Result})
    matrix = OutcomeMatrix(row_ids, results; rev = true)
    distinction_matrix = make_distinction_matrix(matrix)
    return distinction_matrix
end

function make_distinction_matrix(individuals::Vector{<:Individual}, results::Vector{<:Result})
    matrix = OutcomeMatrix(individuals, results; rev = true)
    distinction_matrix = make_distinction_matrix(matrix)
    return distinction_matrix
end

function filter_zero_rows(matrix::OutcomeMatrix)
    zero_rows = findall(==(0.0), sum(matrix.data, dims=2))
    data = matrix.data[setdiff(1:end, [i[1] for i in zero_rows]), :]
    row_ids = matrix.row_ids[setdiff(1:end, [i[1] for i in zero_rows])]
    matrix = OutcomeMatrix(matrix.id, row_ids, matrix.column_ids, data)
    return matrix
end

function get_sorted_dict(matrix::OutcomeMatrix)
    sorted_dict = SortedDict{Int, Vector{Float64}}()
    for (i, row_id) in enumerate(matrix.row_ids)
        sorted_dict[row_id] = matrix[row_id]
    end
    return sorted_dict
end

end
#function implement_competitive_fitness_sharing(outcome_matrix::SortedDict{Int, Vector{Float64}})
#    n_outcomes = length(first(outcome_matrix)[2])
#    outcome_sums = zeros(Float64, n_outcomes)
#    for i in 1:n_outcomes
#        for outcomes in values(outcome_matrix)
#            outcome_sums[i] += outcomes[i]
#        end
#    end
#    new_outcome_matrix = SortedDict{Int, Vector{Float64}}()
#
#    for (id, outcomes) in outcome_matrix
#        new_outcomes = zeros(Float64, n_outcomes)
#        for i in 1:n_outcomes
#            if outcomes[i] == 1
#                new_outcomes[i] = 1 / outcome_sums[i]
#            end
#        end
#        new_outcome_matrix[id] = new_outcomes
#    end
#    return new_outcome_matrix
#end