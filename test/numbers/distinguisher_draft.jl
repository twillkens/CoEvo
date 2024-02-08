
using Test
# Assuming the definitions of Match, Observation, Result, BasicResult, and OutcomeMatrix are accessible

using CoEvo.Abstract
using CoEvo.Interfaces
using CoEvo.Concrete.Matrices.Outcome



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


