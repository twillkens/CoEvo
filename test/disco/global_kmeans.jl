include("../../src/CoEvo.jl")
using .CoEvo.FastGlobalKMeans: get_fast_global_clustering_result, get_derived_tests
using .CoEvo: NSGAIIEvaluator
using .CoEvo: create_evaluation
using .CoEvo.NSGAIIMethods: nsga_tournament

using LinearAlgebra

using Random
using StableRNGs: StableRNG
using StatsBase: mean
using DataStructures: SortedDict

rng = StableRNG(42)

# samples = [
#     [1.0, 0.0], 
#     [0.0, 1.0],
# ]
# result = get_fast_global_clustering_result(rng, samples)
# error, centroids, clusters, bic = result.error, result.centroids, result.cluster_indices, result.bic
# println("error: $error")
# println("centroids: $centroids")
# println("clusters: $clusters")
# println("bic: $bic")
# 
# make_random_number(x) = -x + 2 * x * rand()
# 
# cluster_samples_1 = [
#     [
#         1 + make_random_number(0.1), 
#         make_random_number(0.1),
#         make_random_number(0.1),
#     ] 
#     for x in 1:50
# ]
# cluster_samples_2 = [
#     [
#         make_random_number(0.1),
#         1 + make_random_number(0.1), 
#         make_random_number(0.1),
#     ] 
#     for x in 1:50
# ]
# 
# cluster_samples_3 = [
#     [
#         make_random_number(0.1),
#         make_random_number(0.1),
#         1 + make_random_number(0.1), 
#     ] 
#     for x in 1:50
# ]
# 
# samples = [cluster_samples_1 ; cluster_samples_2]
# result = get_fast_global_clustering_result(rng, samples)
# error, centroids, clusters, bic = result.error, result.centroids, result.cluster_indices, result.bic
# println("error: $error")
# println("centroids: $centroids")
# println("clusters: $clusters")
# println("bic: $bic")
# 
# 
# samples = [cluster_samples_1 ; cluster_samples_2 ; cluster_samples_3]
# result = get_fast_global_clustering_result(rng, samples)
# error, centroids, clusters, bic = result.error, result.centroids, result.cluster_indices, result.bic
# println("error: $error")
# println("centroids: $centroids")
# println("clusters: $clusters")
# println("bic: $bic")
# 
# 
# cluster_samples_1 = [
#     [
#         [1 + make_random_number(0.1) for _ in 1:25] ;
#         [make_random_number(0.1) for _ in 1:25]
#     ] 
#     for x in 1:50
# ]
# cluster_samples_2 = [
#     [
#         [make_random_number(0.1) for _ in 1:25] ;
#         [1 + make_random_number(0.1) for _ in 1:25]
#     ] 
#     for x in 1:50
# ]
# 
# samples = [cluster_samples_1 ; cluster_samples_2]
# result = get_fast_global_clustering_result(rng, samples)
# error, centroids, clusters, bic = result.error, result.centroids, result.cluster_indices, result.bic
# centroids = [[round(x, digits=3) for x in centroid] for centroid in centroids]
# println("error: $error")
# println("centroids: $centroids")
# println("clusters: $clusters")
# println("bic: $bic")
# 
# indiv_ids_1 = SortedDict{Int, Vector{Float64}}(id => sample for (id, sample) in enumerate(cluster_samples_1))
# indiv_ids_2 = SortedDict{Int, Vector{Float64}}(id + 50 => sample for (id, sample) in enumerate(cluster_samples_2))
# 
# indiv_ids = merge(indiv_ids_1, indiv_ids_2)
# 
# tests = get_derived_tests(rng, indiv_ids)
# println("tests: $tests")


tests_1 = Dict(
    1 => 5.0,
    2 => 1.0,
    3 => 3.0,
    4 => 1.0
)

tests_2 = Dict(
    1 => 5.0,
    2 => 2.0,
    3 => 5.0,
    4 => 1.0
)

tests_3 = Dict(
    1 => 1.0,
    2 => 3.0,
    3 => 3.0,
    4 => 5.0
)

tests_4 = Dict(
    1 => 2.0,
    2 => 3.0,
    3 => 2.0,
    4 => 3.0
)

outcomes = Dict(
    1 => tests_1,
    2 => tests_2,
    3 => tests_3,
    4 => tests_4,
)
evaluator = NSGAIIEvaluator(
    maximize = true,
    perform_disco = true,
    include_parents = false,
    max_clusters = 2
)

evaluation = create_evaluation(evaluator, rng, outcomes, [1, 2, 3, 4])
println("evaluation: $evaluation")
winners = [nsga_tournament(rng, evaluation.records, 2) for _ in 1:10_000]
winner_ids = [winner.id for winner in winners]
println("winner_ids: $winner_ids")

using Plots

histogram(winner_ids, bins=20, xlabel="Value", ylabel="Frequency", title="Histogram Example")

# cluster_samples_3 = [
#     [
#         make_random_number(0.1),
#         make_random_number(0.1),
#         1 + make_random_number(0.1), 
#     ] 
#     for x in 1:50
# ]


#using Test
#
## Test Euclidean Distance
#@testset "Euclidean Distance Tests" begin
#    @test eucli_dist([0, 0], [3, 4]) ≈ 5.0  # 3-4-5 right triangle
#    @test eucli_dist([0, 0], [0, 0]) == 0.0  # Identical points
#end
#
## Test Squared Euclidean Distance
#@testset "Squared Euclidean Distance Tests" begin
#    @test sq_eucli_dist([0, 0], [3, 4]) == 25.0  # Square of 3-4-5 right triangle hypotenuse
#    @test sq_eucli_dist([0, 0], [0, 0]) == 0.0   # Identical points
#end
#
## Test Power of 2 check
#@testset "Power of 2 Tests" begin
#    @test is_power2(1)
#    @test is_power2(2)
#    @test !is_power2(3)
#    @test is_power2(16)
#    @test !is_power2(18)
#end
#
## # Test Random KMeans clustering
## @testset "Random KMeans Tests" begin
##     samples = [[2.0, 3.0], [8.0, 10.0], [5.0, 7.0], [7.0, 9.0], [6.0, 8.0]]
##     error, centroids, partitions = random_kmeans(samples, 2, 0.001, [samples[1], samples[2]])
##     @test length(centroids) == 2
##     @test length(partitions) == 2
##     @test error <= 20.0  # This value is an estimate; it might change based on cluster formation
## end
## 
# # Test Fast Global KMeans clustering
# @testset "Fast Global KMeans Tests" begin
#     fg = FastGlobal(5)
#     samples = [[2.0, 3.0], [8.0, 10.0], [5.0, 7.0], [7.0, 9.0], [6.0, 8.0]]
#     error, centroids = fast_global_clustering(fg, samples, 5, 0.001, 0.001)
#     @test length(centroids) == 2
#     @test error <= 20.0  # This value is an estimate; it might change based on cluster formation
# end
#@testset "Fast Global KMeans 2" begin
#    fg = FastGlobal(5)
#    samples = [
#        [1.0, 0.0], 
#        [0.0, 1.0],
#    ]
#    error, centroids = fast_global_clustering(fg, samples, 5, 0.001, 0.001)
#    println("error: $error")
#    println("centroids: $centroids")
#    @test length(centroids) == 2
#    @test error <= 20.0  # This value is an estimate; it might change based on cluster formation
#
#end

# @testset "Fast Global KMeans 2" begin
#     fg = FastGlobal(5)
#     samples = [
#         [1.0, 0.0, 0.0], 
#         [1.0, 0.0, 0.0],
#         [0.0, 1.0, 0.0],
#         [0.0, 1.0, 0.0],
#         [0.0, 0.0, 1.0],
#         [0.0, 0.0, 1.0],
#     ]
#     error, centroids = fast_global_clustering(fg, samples, 5, 0.001, 0.001)
#     println("error: $error")
#     println("centroids: $centroids")
#     @test length(centroids) == 3
#     @test error <= 20.0  # This value is an estimate; it might change based on cluster formation
# 
# end
    # x1 = [
    #     [1.0, 0.0], 
    #     [1.0, 0.0],
    #     [0.0, 1.0],
    #     [0.0, 1.0],
    # ]
    # x2 = [
    #     [1.0, 0.0, 0.0], 
    #     [1.0, 0.0, 0.0],
    #     [0.0, 1.0, 0.0],
    #     [0.0, 1.0, 0.0],
    # ]
    # x3 = [
    #     [1.0, 0.0, 0.0], 
    #     [1.0, 0.0, 0.0],
    #     [0.0, 1.0, 0.0],
    #     [0.0, 1.0, 0.0],
    #     [0.0, 0.0, 1.0],
    #     [0.0, 0.0, 1.0],
    # ]
# function fast_global_clustering(
#     fg::FastGlobal, 
#     samples::Vector{Vector{Float64}}, 
#     cluster_count::Int, 
#     tolerance::Float64
# )
#     fg.sample_dimension = length(samples[1])
# 
#     initial_centroids = [samples[1]]
#     current_error, centroids, clusters = random_kmeans(samples, 1, tolerance, initial_centroids)
#     selected_centroids = [centroids[1]]
# 
#     build_tree!(fg, samples)
# 
#     bucket_keys = is_power2(fg.bucket_count) ? generate_power2_keys(fg) : generate_non_power2_keys(fg)
#     potential_centroids = [vec(mean(fg.partitions[key], dims=1)...) for key in bucket_keys]
# 
#     for cluster_size in 2:cluster_count
#         b_values = [compute_b_value(centroid, clusters, selected_centroids) for centroid in potential_centroids]
#         new_centroid_idx = argmax(b_values)
#         push!(selected_centroids, potential_centroids[new_centroid_idx])
#         current_error, centroids, clusters = random_kmeans(samples, cluster_size, tolerance, selected_centroids)
#         selected_centroids = centroids
#     end
# 
#     return round(current_error, digits=4), selected_centroids
# end