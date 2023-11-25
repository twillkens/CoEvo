using Test

import CoEvo.Phenotypes: Phenotype, act!, reset!

@testset "ContinuousPredictionGame" begin

using CoEvo
using CoEvo.Environments.ContinuousPredictionGame

struct MockPhenotype <: Phenotype 
    movement_constant::Float32
end

function circle_distance(a::Real, b::Real)
    diff = abs(a - b)
    return min(diff, 2π - diff)
end

# Helper function to mock `act!`
function CoEvo.Phenotypes.act!(entity::MockPhenotype, ::Vector{Float32})
    # Return a mock action vector based on input
    return Float32[entity.movement_constant, 2.0, 3.0]
end

function CoEvo.Phenotypes.reset!(entity::MockPhenotype)
    # Reset the entity
    return nothing
end

@testset "step!" begin
    domain_mock = PredictionGameDomain("Control")
    entity1_mock = MockPhenotype(Inf32)
    entity2_mock = MockPhenotype(-Inf32)
    environment_creator = ContinuousPredictionGameEnvironmentCreator(
        domain=domain_mock, episode_length=2, communication_dimension=2
    )
    environment_mock = create_environment(
        environment_creator, 
        Phenotype[entity1_mock, entity2_mock]
    )
    @test is_active(environment_mock)
    step!(environment_mock)
    @test is_active(environment_mock)

    @test environment_mock.position_1 ≈ environment_mock.position_2
    @test environment_mock.distances[1] ≈ 0.0f0
    @test environment_mock.current_communication_1 == Float32[atan(2.0), atan(3.0)]
    @test environment_mock.current_communication_2 == Float32[atan(2.0), atan(3.0)]

    step!(environment_mock)
    @test !is_active(environment_mock)

    @test circle_distance(environment_mock.position_1, 0) ≈ 0.0f0
    @test circle_distance(environment_mock.position_2, π) ≈ 0.0f0
    @test environment_mock.distances[2] ≈ Float32(π)
end


abstract type FakePhenotype <: Phenotype end
reset!(entity::FakePhenotype) = nothing


mutable struct MockPhenotypeWithTape <: FakePhenotype
    tape::Vector{Float32}
end

function CoEvo.Phenotypes.act!(entity::MockPhenotypeWithTape, ::Vector{Float32})
    movement = popfirst!(entity.tape)
    return Float32[movement]
end

function CoEvo.Phenotypes.reset!(entity::MockPhenotypeWithTape)
    return nothing
end

@testset "Reversal Movement" begin
    # Movement for entity1 is towards the right, entity2 is towards the left.
    domain_mock = PredictionGameDomain("Affinitive")
    entity1_mock = MockPhenotypeWithTape([tan(π / 4) for _ in 1:4])  # Moves right for 8 steps
    entity2_mock = MockPhenotypeWithTape([-tan(π / 4) for _ in 1:4]) # Moves left for 8 steps
    environment_mock = create_environment(
        ContinuousPredictionGameEnvironmentCreator(
            domain=domain_mock, episode_length=4, communication_dimension=0
        ), 
        Phenotype[entity1_mock, entity2_mock]
    )
    
    @test circle_distance(environment_mock.position_1, π) < 0.1
    @test circle_distance(environment_mock.position_2, 0) < 0.1

    step!(environment_mock)
    @test circle_distance(environment_mock.position_1, 3π/4) < 0.1
    @test circle_distance(environment_mock.position_2, π/4) < 0.1

    step!(environment_mock)
    @test circle_distance(environment_mock.position_1, π/2) < 0.1
    @test circle_distance(environment_mock.position_2, π/2) < 0.1

    step!(environment_mock)
    @test circle_distance(environment_mock.position_1, π/4) < 0.1
    @test circle_distance(environment_mock.position_2, 3π/4) < 0.1

    step!(environment_mock)
    @test circle_distance(environment_mock.position_1, 0) < 0.1
    @test circle_distance(environment_mock.position_2, π) < 0.1
    expected_distances = [π/2, 0.0, π/2, π]
    @test environment_mock.distances ≈ expected_distances
    expected_distance_sum = sum(expected_distances)
    maximum_distance_score = π * 4
    expected_score = expected_distance_sum / maximum_distance_score 
    @test isapprox(get_outcome_set(environment_mock), [expected_score, expected_score]; atol=1e-4)
end

@testset "Circular Movement" begin
    # Movement for entity1 is towards the right (clockwise) and entity2 is also towards the right (clockwise).
    domain_mock = PredictionGameDomain("Affinitive")
    entity1_mock = MockPhenotypeWithTape([tan(π / 4) for _ in 1:16])  # Moves right for 16 steps
    entity2_mock = MockPhenotypeWithTape([tan(π / 4) for _ in 1:16])  # Moves right for 16 steps
    
    environment_mock = create_environment(
        ContinuousPredictionGameEnvironmentCreator(
            domain=domain_mock, episode_length=16, communication_dimension = 0
        ), 
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
        step!(environment_mock)
    end
end

@testset "Opposing Movement" begin
    # Movement for entity1 is towards the right (clockwise) while entity2 is towards the left (counterclockwise).
    domain_mock = PredictionGameDomain("Affinitive")
    entity1_mock = MockPhenotypeWithTape([tan(π / 4) for _ in 1:16])  # Moves right (clockwise) for 16 steps
    entity2_mock = MockPhenotypeWithTape([-tan(π / 4) for _ in 1:16])  # Moves left (counterclockwise) for 16 steps
    
    environment_mock = create_environment(
        ContinuousPredictionGameEnvironmentCreator(
        domain=domain_mock, episode_length=16), 
        Phenotype[entity1_mock, entity2_mock]
    )

    expected_positions_1 = round.(Float32.(vcat([[π, 3π/4, π/2, π/4, 0.0, 7π/4, 3π/2, 5π/4,] for _ in 1:2]...)), digits=2)
    expected_positions_2 = round.(Float32.(vcat([[0.0, π/4, π/2, 3π/4, π, 5π/4, 3π/2, 7π/4,] for _ in 1:2]...)), digits=2)

    expected_clockwise_distances = Float32.(
        round.(vcat([[π, π/2, 0.0, 3π/2] for _ in 1:4]...), digits=2)
    )
    expected_counterclockwise_distances = Float32.(
        round.(vcat([[π, 3π/2, 0, π/2] for _ in 1:4]...), digits=2)
    )

    for i in 1:16
        
        actual_clockwise_distance = round(get_clockwise_distance(
            environment_mock.position_1, environment_mock.position_2,
        ), digits = 2)
        actual_counterclockwise_distance = round(get_counterclockwise_distance(
            environment_mock.position_1, environment_mock.position_2,
        ), digits = 2)

        position_1 = round(environment_mock.position_1, digits=2)
        position_2 = round(environment_mock.position_2, digits=2)
        @test circle_distance(position_1, expected_positions_1[i]) < 0.1
        @test circle_distance(position_2, expected_positions_2[i]) < 0.1

        @test expected_clockwise_distances[i] == actual_clockwise_distance
        @test expected_counterclockwise_distances[i] == actual_counterclockwise_distance

        step!(environment_mock)
    end
end

end