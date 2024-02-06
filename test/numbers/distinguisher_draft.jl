
using Test
# Assuming the definitions of Match, Observation, Result, BasicResult, and OutcomeMatrix are accessible

abstract type Match end
abstract type Observation end
abstract type Result end

struct OutcomeMatrix{T, U, V}
    id::T
    row_ids::Vector{U}
    column_ids::Vector{V}
    data::Matrix{Float64}
end

import Base: getindex

# Get a row by row_id, accommodating idiosyncratic IDs
function getindex(matrix::OutcomeMatrix, row_id)
    row_index = findfirst(==(row_id), matrix.row_ids)
    if row_index === nothing
        throw(ArgumentError("Row ID $row_id not found"))
    end
    return matrix.data[row_index, :]
end

# Get a column by column_id, accommodating idiosyncratic IDs
function getindex(matrix::OutcomeMatrix, ::Colon, column_id)
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
            data[i, j] = matrix[matrix.row_ids[i], id_1] != matrix[matrix.row_ids[i], id_2] ? 1.0 : 0.0
        end
    end
    return OutcomeMatrix(matrix.id, matrix.row_ids, column_pairs, data)
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

function filter_zero_rows(matrix::OutcomeMatrix)
    zero_rows = findall(==(0.0), sum(matrix.data, dims=2))
    data = matrix.data[setdiff(1:end, zero_rows), :]
    row_ids = matrix.row_ids[setdiff(1:end, zero_rows)]
    return OutcomeMatrix(matrix.id, row_ids, matrix.column_ids, data)
end

function get_sorted_dict(matrix::OutcomeMatrix)
    sorted_dict = SortedDict{Int, Vector{Float64}}()
    for (i, row_id) in enumerate(matrix.row_ids)
        sorted_dict[row_id] = matrix[row_id]
    end
    return sorted_dict
end


struct SimpleMatch <: Match
    individual_ids::Tuple{Int, Int}
end

struct SimpleObservation <: Observation
    details::String
end

struct BasicResult{M <: Match, O <: Observation} <: Result
    match::M
    outcome_set::Vector{Float64}
    observation::O
end

# Your OutcomeMatrix definition here

# Test Cases
@testset "OutcomeMatrix Construction Tests" begin

    @testset "Simple Matrix Creation with Non-Overlapping IDs" begin
        # Adjusted dummy data with non-overlapping row and column IDs
        results = [
            BasicResult(SimpleMatch((1, 3)), [0.5, 0.4], SimpleObservation("First observation")),
            BasicResult(SimpleMatch((1, 4)), [0.8, 0.9], SimpleObservation("Second observation")),
            BasicResult(SimpleMatch((2, 3)), [0.5, 0.4], SimpleObservation("Third observation")),
            BasicResult(SimpleMatch((2, 4)), [0.6, 0.7], SimpleObservation("Fourth observation")),
        ]

        row_ids = [1, 2]  # IDs for rows
        column_ids = [3, 4]  # Mutually exclusive IDs for columns

        matrix = OutcomeMatrix(row_ids, column_ids, results)
        @test matrix.data ≈ [0.5 0.8; 0.5 0.6]  # Adjusted expectation based on corrected IDs
    end

    @testset "Using rev Parameter with Correct ID Sets" begin
        # Using the same setup as above but testing the 'rev' parameter
        results = [
            BasicResult(SimpleMatch((1, 3)), [0.5, 0.4], SimpleObservation("First observation")),
            BasicResult(SimpleMatch((1, 4)), [0.8, 0.9], SimpleObservation("Second observation")),
            BasicResult(SimpleMatch((2, 3)), [0.5, 0.4], SimpleObservation("Third observation")),
            BasicResult(SimpleMatch((2, 4)), [0.6, 0.7], SimpleObservation("Fourth observation")),
        ]

        row_ids = [1, 2]  # IDs for rows
        column_ids = [3, 4]  # Mutually exclusive IDs for columns

        matrix_rev = OutcomeMatrix(row_ids, column_ids, results, rev=true)
        @test matrix_rev.data ≈ [0.4 0.9; 0.4 0.7]  # Expectation for reversed outcomes
    end

   # @testset "Handling Unmatched IDs Correctly" begin
   #     # Testing with an ID set that includes an unmatched ID
   #     results = [
   #         BasicResult(SimpleMatch((1, 4)), [0.5, 0.4], SimpleObservation("First observation")),
   #         BasicResult(SimpleMatch((2, 5)), [0.6, 0.7], SimpleObservation("Second observation")),
   #         BasicResult(SimpleMatch((1, 5)), [0.8, 0.9], SimpleObservation("Third observation"))
   #     ]

   #     row_ids_unmatched = [1, 3]  # Including an unmatched row ID
   #     column_ids_unmatched = [4, 5]  # Keeping column IDs matched

   #     @test_throws ErrorException OutcomeMatrix(row_ids_unmatched, column_ids_unmatched, results)
   # end
end


