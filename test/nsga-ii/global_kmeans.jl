using Test

@testset "Global K-Means Clustering " begin

using CoEvo
using CoEvo.Names

using LinearAlgebra
using Random
using StableRNGs: StableRNG
using StatsBase: mean
using .Genotypes.Vectors: BasicVectorGenotype
using .Individuals.Basic: BasicIndividual
using .Species.Basic: BasicSpecies
using .Evaluators.NSGAII
using .Clusterers.GlobalKMeans

@testset "Compression of the Interaction Matrix" begin
    random_number_generator = StableRNG(42)

    tests_1 = Dict(1 => 5.0, 2 => 1.0, 3 => 3.0, 4 => 1.0)
    tests_2 = Dict(1 => 5.0, 2 => 2.0, 3 => 5.0, 4 => 1.0)
    tests_3 = Dict(1 => 1.0, 2 => 3.0, 3 => 3.0, 4 => 5.0)
    tests_4 = Dict(1 => 2.0, 2 => 3.0, 3 => 2.0, 4 => 3.0)

    outcomes = Dict{Int64, Dict{Int, Float64}}(
        1 => tests_1,
        2 => tests_2,
        3 => tests_3,
        4 => tests_4,
    )
    evaluator = NSGAIIEvaluator(
        scalar_fitness_evaluator = ScalarFitnessEvaluator(),
        maximize = true,
        perform_disco = true,
        max_clusters = 2,
    )

    population = [
        BasicIndividual(id, BasicVectorGenotype([0.0]), Int[]) for id in 1:4
    ]

    children = [
        BasicIndividual(id, BasicVectorGenotype([0.0]), Int[]) for id in 5:8
    ]

    species = BasicSpecies("species_1", population, children)

    individual_tests = make_individual_tests(species.population, outcomes)

    derived_tests = get_derived_tests(random_number_generator, individual_tests, 2, "euclidean")

    @test derived_tests[1] == [4.0, 1.0]
    @test derived_tests[2] == [5.0, 1.5]
    @test derived_tests[3] == [2.0, 4.0]
    @test derived_tests[4] == [2.0, 3.0]

    evaluation = evaluate(evaluator, random_number_generator, species, outcomes)
    winner_ids = [
        nsga_tournament(random_number_generator, evaluation.records, 2).id for _ in 1:10_000
    ]

    count_1 = sum(winner_id == 1 for winner_id in winner_ids)
    count_2 = sum(winner_id == 2 for winner_id in winner_ids)
    count_3 = sum(winner_id == 3 for winner_id in winner_ids)
    count_4 = sum(winner_id == 4 for winner_id in winner_ids)

    @test count_2 > count_1 && count_2 > count_4
    @test count_3 > count_1 && count_3 > count_4
end

# Test Euclidean Distance
@testset "Euclidean Distance Tests" begin
    @test euclidean_distance([0, 0], [3, 4]) ≈ 5.0  # 3-4-5 right triangle
    @test euclidean_distance([0, 0], [0, 0]) == 0.0  # Identical points
end

# Test Squared Euclidean Distance
@testset "Squared Euclidean Distance Tests" begin
    @test squared_euclidean_distance([0, 0], [3, 4]) == 25.0  # Square of 3-4-5 right triangle hypotenuse
    @test squared_euclidean_distance([0, 0], [0, 0]) == 0.0   # Identical points
end

# Test Power of 2 check
@testset "Power of 2 Tests" begin
    @test is_power2(1)
    @test is_power2(2)
    @test !is_power2(3)
    @test is_power2(16)
    @test !is_power2(18)
end
# 1. Basic Test
@testset "Basic Test" begin
    rng = MersenneTwister(123)
    samples = [[1.0, 1.0], [2.0, 2.0], [10.0, 10.0], [11.0, 11.0]]
    initial_centroids = [[1.0, 1.0], [10.0, 10.0]]
    result = get_kmeans_clustering_result(rng, samples, 2, initial_centroids)
    @test result.centroids == initial_centroids
    @test length(result.clusters) == 2
end

# 2. Convergence Test
@testset "Convergence Test" begin
    rng = MersenneTwister(123)
    samples = [[1.0, 1.0], [2.0, 2.0], [10.0, 10.0], [11.0, 11.0]]
    initial_centroids = [[0.0, 0.0], [20.0, 20.0]]
    result = get_kmeans_clustering_result(rng, samples, 2, initial_centroids)
    @test abs(result.error) ≈ 2.0
end

# 3. Single Cluster Test
@testset "Single Cluster Test" begin
    rng = MersenneTwister(123)
    samples = [[1.0, 1.0], [1.0, 1.0], [1.0, 1.0], [1.0, 1.0]]
    initial_centroids = [[1.0, 1.0]]
    result = get_kmeans_clustering_result(rng, samples, 1, initial_centroids)
    @test result.centroids == initial_centroids
    @test length(result.clusters) == 1
end

# 4. Empty Samples Test
@testset "Empty Samples Test" begin
    rng = MersenneTwister(123)
    samples = Vector{Vector{Float64}}()
    initial_centroids = Vector{Vector{Float64}}()
    @test_throws Exception get_kmeans_clustering_result(rng, samples, 0, initial_centroids)
end

# 5. Centroid Replacement Test
@testset "Centroid Replacement Test" begin
    rng = MersenneTwister(123)
    samples = [[1.0, 1.0], [2.0, 2.0], [10.0, 10.0], [11.0, 11.0]]
    initial_centroids = [[1.0, 1.0], [20.0, 20.0]]  # The second centroid will not have any points closer to it.
    result = get_kmeans_clustering_result(rng, samples, 2, initial_centroids)
    @test !any(c -> c == [20.0, 20.0], result.centroids)
end

 # Test Fast Global KMeans clustering
@testset "Fast Global KMeans Tests" begin
   rng = MersenneTwister(123)
   samples = [[2.0, 3.0], [8.0, 10.0], [5.0, 7.0], [7.0, 9.0], [6.0, 8.0]]
   result = get_fast_global_clustering_result(rng, samples, max_clusters = 2)
   @test length(result.centroids) == 2
   @test result.error <= 20.0 
end

@testset "Fast Global KMeans 2" begin
    rng = MersenneTwister(123)
    samples = [
        [1.0, 0.0], 
        [0.0, 1.0],
    ]
    result = get_fast_global_clustering_result(rng, samples, max_clusters = -1)
    @test length(result.centroids) == 2
    @test result.error <= 20.0 
end

@testset "Fast Global KMeans 2" begin
    rng = MersenneTwister(123)
    samples = [
        [1.0, 0.0, 0.0], 
        [0.9, 0.0, 0.0],
        [0.0, 1.1, 0.0],
        [0.0, 1.0, 0.0],
        [0.0, 0.0, 0.85],
        [0.0, 0.0, 1.1],
    ]
    result = get_fast_global_clustering_result(rng, samples, max_clusters = -1)
    @test length(result.centroids) == 3
    @test result.error <= 20.0 
end


end