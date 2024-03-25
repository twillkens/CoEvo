module Outcome

export OutcomeMatrix, make_distinction_matrix, filter_zero_rows, make_full_distinction_matrix
export filter_identical_columns, filter_rows, filter_columns, transpose
export generate_unique_tuples, filter_identical_columns
export filter_rows, filter_columns, get_nonzero_row_indices, get_unique_column_indices
export merge_matrices
export transpose_and_invert

import Base: getindex, setindex!, show
import Base: transpose

using DataStructures
using LinearAlgebra
using ....Abstract

Base.@kwdef mutable struct OutcomeMatrix{T, U, V, W} 
    id::T
    row_ids::Vector{U}
    column_ids::Vector{V}
    data::Matrix{W}
end

function OutcomeMatrix{W}(id::T, row_ids::Vector{U}, column_ids::Vector{V}) where {T, U, V, W}
    data = zeros(W, length(row_ids), length(column_ids))
    return OutcomeMatrix(id, row_ids, column_ids, data)
end

function Base.show(io::IO, matrix::OutcomeMatrix)
    # Print the ID of the OutcomeMatrix at the top
    println(io, "OutcomeMatrix with ID: ", matrix.id)

    # Print column IDs with proper spacing
    print(io, "     ")  # Space for row ID column
    for col_id in matrix.column_ids
        print(io, " ", lpad(col_id, 6))
    end
    println(io)

    # Print each row with the row ID on the left
    for (i, row_id) in enumerate(matrix.row_ids)
        print(io, lpad(row_id, 4), " |")
        for j in 1:length(matrix.column_ids)
            print(io, " ", lpad(matrix.data[i, j], 6))
        end
        println(io)
    end
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
function getindex(matrix::OutcomeMatrix, row_id::Any, column_id::Any)
    row_index = findfirst(==(row_id), matrix.row_ids)
    column_index = findfirst(==(column_id), matrix.column_ids)
    if row_index === nothing || column_index === nothing
        throw(ArgumentError("Invalid row ID $row_id or column ID $column_id"))
    end
    return matrix.data[row_index, column_index]
end

function setindex!(
    matrix::OutcomeMatrix{T, U, V, W}, value::Any, row_id::U, column_id::V, 
) where {T, U, V, W}
    row_index = findfirst(==(row_id), matrix.row_ids)
    column_index = findfirst(==(column_id), matrix.column_ids)
    if row_index === nothing || column_index === nothing
        throw(ArgumentError("Invalid row ID $row_id or column ID $column_id"))
    end
    matrix.data[row_index, column_index] = W(value)
end

function OutcomeMatrix{W}(id::String, row_ids::Vector, column_ids::Vector) where W
    data = zeros(W, length(row_ids), length(column_ids))
    matrix = OutcomeMatrix(id, row_ids, column_ids, data)
    return matrix
end

function OutcomeMatrix(data::Matrix)
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

function vecvec_to_matrix(x)
    X = zeros(length(first(x)), length(x))
    for (i, y) in enumerate(x)
        X[:, i] = y
    end
    return X
end
function OutcomeMatrix(samples::Vector{Vector{Float64}}; do_transpose::Bool = false)
    data = vecvec_to_matrix(samples)
    if do_transpose
        data = collect(transpose(data))
    end
    matrix = OutcomeMatrix(data)
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

get_nonzero_row_indices(matrix::Matrix) = findall(row -> norm(row) != 0, eachrow(matrix))

# Filter out rows that contain all zeros
function filter_zero_rows(matrix::OutcomeMatrix)
    non_zero_row_indices = get_nonzero_row_indices(matrix.data)
    matrix = OutcomeMatrix(
        matrix.id, 
        matrix.row_ids[non_zero_row_indices], 
        matrix.column_ids, 
        matrix.data[non_zero_row_indices, :]
    )
    return matrix
end

function get_unique_column_indices(matrix::Matrix)
    unique_cols = unique(eachcol(matrix), dims=2)
    unique_col_indices = unique([findfirst(isequal(col), eachcol(matrix)) for col in unique_cols])
    return unique_col_indices
end

# Filter out columns that are identical across all rows
function filter_identical_columns(matrix::OutcomeMatrix)
    unique_col_indices = get_unique_column_indices(matrix.data)
    matrix = OutcomeMatrix(
        matrix.id, 
        matrix.row_ids, 
        matrix.column_ids[unique_col_indices], 
        matrix.data[:, unique_col_indices]
    )
    return matrix
end

function transpose(matrix::OutcomeMatrix)
    # Transpose the data matrix
    transposed_data = collect(transpose(matrix.data))
    
    # Swap row_ids and column_ids to reflect the transposition
    new_row_ids = deepcopy(matrix.column_ids)
    new_column_ids = deepcopy(matrix.row_ids)
    
    # Return a new OutcomeMatrix with the transposed data and swapped IDs
    # Assuming the 'id' field should remain unchanged during transpose
    return OutcomeMatrix(matrix.id, new_row_ids, new_column_ids, transposed_data)
end

function transpose_and_invert(matrix::OutcomeMatrix)
    # Transpose the data matrix
    transposed_data = collect(transpose(matrix.data))
    
    # Swap row_ids and column_ids to reflect the transposition
    new_row_ids = deepcopy(matrix.column_ids)
    new_column_ids = deepcopy(matrix.row_ids)
    
    # Invert the data matrix
    inverted_data = 1 .- transposed_data
    
    # Return a new OutcomeMatrix with the transposed data and swapped IDs
    # Assuming the 'id' field should remain unchanged during transpose
    return OutcomeMatrix(matrix.id, new_row_ids, new_column_ids, inverted_data)
end

function filter_rows(matrix::OutcomeMatrix, ids::Vector)
    ids = unique(ids)
    row_indices = findall(id -> id in ids, matrix.row_ids)
    if isempty(row_indices)
        println("matrix = ", matrix)
        println("ids = ", ids)
        throw(ArgumentError("None of the specified row IDs found"))
    end
    if length(row_indices) != length(ids)
        println("matrix = ", matrix)
        println("ids = ", ids)
        throw(ArgumentError("Some row IDs were not found"))
    end
    new_data = matrix.data[row_indices, :]
    new_row_ids = matrix.row_ids[row_indices]
    # Return a new OutcomeMatrix with the filtered rows
    return OutcomeMatrix(matrix.id, new_row_ids, matrix.column_ids, new_data)
end

function filter_columns(matrix::OutcomeMatrix, ids::Vector)
    ids = unique(ids)
    column_indices = findall(id -> id in ids, matrix.column_ids)
    if isempty(column_indices)
        println("matrix = ", matrix)
        println("ids = ", ids)
        throw(ArgumentError("None of the specified column IDs found"))
    end
    new_data = matrix.data[:, column_indices]
    new_column_ids = matrix.column_ids[column_indices]
    # Return a new OutcomeMatrix with the filtered columns
    return OutcomeMatrix(matrix.id, matrix.row_ids, new_column_ids, new_data)
end

function filter_matrix(matrix::OutcomeMatrix, row_ids::Vector, column_ids::Vector)
    new_matrix = filter_rows(matrix, row_ids)
    new_matrix = filter_columns(new_matrix, column_ids)
    return new_matrix
end


function generate_all_tuples(n::Int)
    all_tuples = [(i, j) for i in 1:n for j in 1:n if i != j]
    return all_tuples
end

function make_full_distinction_matrix(matrix::Matrix)
    nrows, ncols = size(matrix)
    col_pairs = generate_all_tuples(ncols)
    data = zeros(Bool, nrows, length(col_pairs))
    for i in 1:nrows
        for (j, (col_1, col_2)) in enumerate(col_pairs)
            data[i, j] = matrix[i, col_1] > matrix[i, col_2] ? 1 : 0
        end
    end
    return data
end

function generate_all_tuples(ids::Vector{T}) where T
    all_tuples = [(ids[i], ids[j]) for i in 1:length(ids) for j in 1:length(ids) if i != j]
    return all_tuples
end

function make_full_distinction_matrix(matrix::OutcomeMatrix; id = matrix.id)
    # Convert OutcomeMatrix to Matrix{Float64}
    distinction_matrix = make_full_distinction_matrix(matrix.data)
    # Convert back to OutcomeMatrix if necessary, depending on the desired output format
    row_ids = deepcopy(matrix.row_ids)
    column_ids = generate_all_tuples(matrix.column_ids)
    matrix = OutcomeMatrix(
        id = id, row_ids = row_ids, column_ids = column_ids, data = distinction_matrix
    )
    return matrix
end

function merge_matrices(
    matrix1::OutcomeMatrix{T, U, V, W}, matrix2::OutcomeMatrix{T, U, V, W}
) where {T, U, V, W}
    # Combine and sort row and column IDs, excluding duplicates
    combined_row_ids = unique(sort(vcat(matrix1.row_ids, matrix2.row_ids)))
    combined_column_ids = unique(sort(vcat(matrix1.column_ids, matrix2.column_ids)))
    rows_1 = Set(matrix1.row_ids)
    rows_2 = Set(matrix2.row_ids)
    columns_1 = Set(matrix1.column_ids)
    columns_2 = Set(matrix2.column_ids)

    # Initialize the new matrix with zeros
    zero_data = zeros(W, length(combined_row_ids), length(combined_column_ids))
    new_matrix = OutcomeMatrix(matrix1.id, combined_row_ids, combined_column_ids, zero_data)
    for row_id in new_matrix.row_ids
        for col_id in new_matrix.column_ids
            first_has_item = row_id in rows_1 && col_id in columns_1
            if first_has_item
                new_matrix[row_id, col_id] = matrix1[row_id, col_id]
            else
                new_matrix[row_id, col_id] = matrix2[row_id, col_id]
            end
        end
    end
    return new_matrix
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