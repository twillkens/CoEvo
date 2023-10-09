using Test
include("../../src/CoEvo.jl")
using .CoEvo
using .TapeMethods.ContinuousPredictionGame: scaled_arctangent, apply_movement, get_action!
using .TapeMethods.ContinuousPredictionGame: get_outcome_set
import .Phenotypes.Interfaces: act!
# Assuming necessary modules and structs have been imported...

# Test scaled_arctangent function
@testset "scaled_arctangent" begin
    @test scaled_arctangent(1.0, π/4) ≈ (π/4) * atan(1.0) / (π/2)
    @test scaled_arctangent(0.0, π/4) == 0.0
    @test scaled_arctangent(-1.0, π/4) ≈ -(π/4) * atan(1.0) / (π/2)
end

# Test apply_movement function
@testset "apply_movement" begin
    @test round(apply_movement(π, π), digits=5) ≈ 0.0
    @test apply_movement(π/2, π) ≈ 3π/2
    @test apply_movement(π, -π/2) ≈ π/2
end

struct MockPhenotype <: Phenotype end

# Helper function to mock `act!`
function act!(entity::MockPhenotype, input::Vector{Float32})
    # Return a mock action vector based on input
    return Float32[sum(input), 2.0, 3.0]
end

# Test get_action function
@testset "get_action" begin
    entity_mock = MockPhenotype()
    communication_mock = Float32[1.0, 2.0]
    move_output, comm_output = get_action!(entity_mock, 1.0f0, 2.0f0, communication_mock, Float32(π/4))
    @test move_output ≈ Float32((π/4) * atan(6.0) / (π/2))
    @test comm_output == Float32[2.0, 3.0]
end

# Mock other necessary structures and functions for the next! test

@testset "next!" begin
    domain_mock = ContinuousPredictionGameDomain(:Control)
    entity1_mock = MockPhenotype()
    entity2_mock = MockPhenotype()
    environment_mock = TapeEnvironment(
        domain = domain_mock,
        entity_1 = entity1_mock, 
        entity_2 = entity2_mock, 
        episode_length = 10
    )
    next!(environment_mock)
    @test environment_mock.position_1 ≠ environment_mock.position_2
    @test length(environment_mock.distances) == 1
    @test environment_mock.communication_1 == Float32[2.0, 3.0]
    @test environment_mock.communication_2 == Float32[2.0, 3.0]
end

# @testset "get_outcome_set" begin
#     domain_mock = ContinuousPredictionGameDomain(:Control)
#     entity1_mock = MockPhenotype()
#     entity2_mock = MockPhenotype()
#     environment_mock = TapeEnvironment(domain_mock, entity1_mock, entity2_mock, 10, π, 0.0)
#     outcome = get_outcome_set(environment_mock)
#     @test outcome == sum(environment_mock.distances) / (π * 10)
# end
# 