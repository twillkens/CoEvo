using Test
include("../../src/CoEvo.jl")
using .CoEvo
using .TapeMethods.ContinuousPredictionGame: scaled_arctangent, apply_movement, get_action!
using .TapeMethods.ContinuousPredictionGame: get_outcome_set, get_clockwise_distance, get_counterclockwise_distance
import .Phenotypes.Interfaces: act!, reset!
# Assuming necessary modules and structs have been imported...

# Test scaled_arctangent function
# @testset "scaled_arctangent" begin
#     @test scaled_arctangent(1.0, π/4) ≈ (π/4) * atan(1.0) / (π/2)
#     @test scaled_arctangent(0.0, π/4) == 0.0
#     @test scaled_arctangent(-1.0, π/4) ≈ -(π/4) * atan(1.0) / (π/2)
# end
# 
# # Test apply_movement function
# @testset "apply_movement" begin
#     @test round(apply_movement(π, π), digits=5) ≈ 0.0
#     @test apply_movement(π/2, π) ≈ 3π/2
#     @test apply_movement(π, -π/2) ≈ π/2
# end
# 
struct MockPhenotype <: Phenotype end

# Helper function to mock `act!`
function act!(entity::MockPhenotype, input::Vector{Float32})
    # Return a mock action vector based on input
    return Float32[sum(input), 2.0, 3.0]
end

# Test get_action function
# @testset "get_action" begin
#     entity_mock = MockPhenotype()
#     communication_mock = Float32[1.0, 2.0]
#     move_output, comm_output = get_action!(entity_mock, 1.0f0, 2.0f0, communication_mock, Float32(π/4))
#     @test move_output ≈ Float32((π/4) * atan(6.0) / (π/2))
#     @test comm_output == Float32[2.0, 3.0]
# end
# 
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

abstract type FakePhenotype <: Phenotype end
reset!(entity::FakePhenotype) = nothing


mutable struct MockPhenotypeWithTape <: FakePhenotype
    tape::Vector{Float32}
end

function act!(entity::MockPhenotypeWithTape, ::Vector{Float32})
    movement = popfirst!(entity.tape)
    return Float32[movement, 2.0, 3.0]
end


function circle_distance(a::Real, b::Real)
    diff = abs(a - b)
    return min(diff, 2π - diff)
end
 
@testset "Reversal Movement" begin
    # Movement for entity1 is towards the right, entity2 is towards the left.
    domain_mock = ContinuousPredictionGameDomain(:CooperativeMatching)
    entity1_mock = MockPhenotypeWithTape([tan(π / 4) for _ in 1:4])  # Moves right for 8 steps
    entity2_mock = MockPhenotypeWithTape([-tan(π / 4) for _ in 1:4]) # Moves left for 8 steps
    environment_mock = create_environment(TapeEnvironmentCreator(
        domain=domain_mock, episode_length=4), 
        Phenotype[entity1_mock, entity2_mock]
    )
    
    @test circle_distance(environment_mock.position_1, π) < 0.1
    @test circle_distance(environment_mock.position_2, 0) < 0.1

    next!(environment_mock)
    @test circle_distance(environment_mock.position_1, 3π/4) < 0.1
    @test circle_distance(environment_mock.position_2, π/4) < 0.1

    next!(environment_mock)
    @test circle_distance(environment_mock.position_1, π/2) < 0.1
    @test circle_distance(environment_mock.position_2, π/2) < 0.1


    next!(environment_mock)
    @test circle_distance(environment_mock.position_1, π/4) < 0.1
    @test circle_distance(environment_mock.position_2, 3π/4) < 0.1


    next!(environment_mock)
    @test circle_distance(environment_mock.position_1, 0) < 0.1
    @test circle_distance(environment_mock.position_2, π) < 0.1
    expected_distances = [π, π/2, 0.0, π/2]
    @test environment_mock.distances ≈ expected_distances
    expected_final_distances = [π/2, 0.0, π/2, π]
    expected_distance_sum = sum(expected_final_distances)
    maximum_distance_score = π * 4
    expected_score = expected_distance_sum / maximum_distance_score 
    @test isapprox(get_outcome_set(environment_mock), [expected_score, expected_score]; atol=1e-4)
end

@testset "Circular Movement" begin
    # Movement for entity1 is towards the right (clockwise) and entity2 is also towards the right (clockwise).
    domain_mock = ContinuousPredictionGameDomain(:CooperativeMatching)
    entity1_mock = MockPhenotypeWithTape([tan(π / 4) for _ in 1:16])  # Moves right for 16 steps
    entity2_mock = MockPhenotypeWithTape([tan(π / 4) for _ in 1:16])  # Moves right for 16 steps
    
    environment_mock = create_environment(TapeEnvironmentCreator(
        domain=domain_mock, episode_length=16), 
        Phenotype[entity1_mock, entity2_mock]
    )

    expected_positions_1 = vcat([[π, 3π/4, π/2, π/4, 0.0, 7π/4, 3π/2, 5π/4,] for _ in 1:2]...)
    expected_positions_2 = vcat([[0.0, 7π/4, 3π/2, 5π/4, π, 3π/4, π/2, π/4,] for _ in 1:2]...)
    expected_clockwise_distances = [π for _ in 1:16]
    expected_counterclockwise_distances = [π for _ in 1:16]
    
    for i in 1:16
        @test circle_distance(environment_mock.position_1, expected_positions_1[i]) < 0.1
        @test circle_distance(environment_mock.position_2, expected_positions_2[i]) < 0.1
        @test get_clockwise_distance(
            environment_mock.position_1, environment_mock.position_2,
        ) ≈ expected_clockwise_distances[i]
        @test get_counterclockwise_distance(
            environment_mock.position_1, environment_mock.position_2,
        ) ≈ expected_clockwise_distances[i]
        next!(environment_mock)
    end
end

@testset "Opposing Movement" begin
    # Movement for entity1 is towards the right (clockwise) while entity2 is towards the left (counterclockwise).
    domain_mock = ContinuousPredictionGameDomain(:CooperativeMatching)
    entity1_mock = MockPhenotypeWithTape([tan(π / 4) for _ in 1:16])  # Moves right (clockwise) for 16 steps
    entity2_mock = MockPhenotypeWithTape([-tan(π / 4) for _ in 1:16])  # Moves left (counterclockwise) for 16 steps
    
    environment_mock = create_environment(TapeEnvironmentCreator(
        domain=domain_mock, episode_length=16), 
        Phenotype[entity1_mock, entity2_mock]
    )

    expected_positions_1 = vcat([[π, 3π/4, π/2, π/4, 0.0, 7π/4, 3π/2, 5π/4,] for _ in 1:2]...)
    expected_positions_2 = vcat([[0.0, π/4, π/2, 3π/4, π, 5π/4, 3π/2, 7π/4,] for _ in 1:2]...)

    expected_clockwise_distances = round.(vcat([[π, π/2, 0.0, 3π/2] for _ in 1:4]...), digits=2)
    expected_counterclockwise_distances = round.(vcat([[π, 3π/2, 0, π/2] for _ in 1:4]...), digits=2)

    for i in 1:16
        # @test circle_distance(environment_mock.position_1, expected_positions_1[i]) < 0.1
        # @test circle_distance(environment_mock.position_2, expected_positions_2[i]) < 0.1
        
        actual_clockwise_distance = round(get_clockwise_distance(
            environment_mock.position_1, environment_mock.position_2,
        ), digits = 2)
        actual_counterclockwise_distance = round(get_counterclockwise_distance(
            environment_mock.position_1, environment_mock.position_2,
        ), digits = 2)

        println("-----Timestep: $i-----")
        position_1 = round(environment_mock.position_1, digits=2)
        position_2 = round(environment_mock.position_2, digits=2)
        println("position_1: $position_1, position_2: $position_2")
        println("expected_clockwise_distance: $(expected_clockwise_distances[i]), actual: $actual_clockwise_distance")
        println("expected_counterclockwise_distance: $(expected_counterclockwise_distances[i]), actual: $actual_counterclockwise_distance")

        # @test isapprox(actual_clockwise_distance, expected_clockwise_distances[i]; atol=0.1)
        # @test isapprox(actual_counterclockwise_distance, expected_counterclockwise_distances[i]; atol=0.1)

        next!(environment_mock)
    end
end

# @testset "Max Distance Movement" begin
#     # Both entities move in unison.
#     entity1_mock = MockPhenotypeWithTape([π/16 for _ in 1:8])  # Moves right
#     entity2_mock = MockPhenotypeWithTape([π/16 for _ in 1:8])  # Moves right
#     environment_mock = create_environment(
#         TapeEnvironmentCreator(domain=domain_mock, episode_length=8), Phenotype[entity1_mock, entity2_mock])
#     
#     initial_distance = get_clockwise_distance(environment_mock.position_1, environment_mock.position_2)
#     for _ in 1:8
#         next!(environment_mock)
#     end
#     
#     @test get_clockwise_distance(environment_mock.position_1, environment_mock.position_2) ≈ initial_distance
# end
# 
# @testset "Meet in the Middle" begin
#     # Both entities move towards π/2 for 4 steps, then to 3π/2 for another 4 steps.
#     entity1_mock = MockPhenotypeWithTape([[π/16 for _ in 1:4] ; [-π/16 for _ in 1:4]])  # 4 right, 4 left
#     entity2_mock = MockPhenotypeWithTape([[π/16 for _ in 1:4] ; [-π/16 for _ in 1:4]])  # 4 right, 4 left
#     environment_mock = create_environment(TapeEnvironmentCreator(domain=domain_mock, episode_length=8), Phenotype[entity1_mock, entity2_mock])
#     
#     for _ in 1:4
#         next!(environment_mock)
#     end
#     @test environment_mock.position_1 ≈ π/2
#     @test environment_mock.position_2 ≈ π/2
# 
#     for _ in 1:4
#         next!(environment_mock)
#     end
#     @test environment_mock.position_1 ≈ 3π/2
#     @test environment_mock.position_2 ≈ 3π/2
# end


# @testset "get_outcome_set" begin
#     domain_mock = ContinuousPredictionGameDomain(:Control)
#     entity1_mock = MockPhenotype()
#     entity2_mock = MockPhenotype()
#     environment_mock = TapeEnvironment(domain_mock, entity1_mock, entity2_mock, 10, π, 0.0)
#     outcome = get_outcome_set(environment_mock)
#     @test outcome == sum(environment_mock.distances) / (π * 10)
# end
# 