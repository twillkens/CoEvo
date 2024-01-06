
using Test

using CoEvo.Clusterers.XMeans
using LinearAlgebra
using Random
using StableRNGs: StableRNG
using StatsBase: mean
using DataStructures

rng = StableRNG(44)

# Assuming the kmeans_plus_plus_init function and euclidean_distance function are already defined
function generate_cluster(centroid, num_points, spread)
    return [centroid + spread * round.(randn(rng, length(centroid)); digits=2) for _ in 1:num_points]
end

@inline function euclidean_distance(sample::Vector{T}, center::Vector{T}) where T
    @assert length(sample) == length(center)
    s = zero(T)
    @simd for i in eachindex(sample)
        Δ = sample[i] - center[i]
        s += Δ * Δ
    end
    return sqrt(s)
end

# Test if the initialized centroids are close to the true centroids
function is_close_to_any_centroid(centroid, true_centroids, threshold)
    return any(euclidean_distance(centroid, tc) < threshold for tc in true_centroids)
end

@testset "Xmeans" begin
    # Assuming generate_cluster, kmeans_plus_plus_init, and x_means_clustering are defined

    # Generate the dataset with 5 clusters
    true_centroids = [[0.0, 0.0, 0.0], [2.0, 2.0, 2.0], [4.0, 4.0, 4.0], ]
    spread = 0.1
    samples = vcat([generate_cluster(tc, 3, spread) for tc in true_centroids]...)

    # Run X-Means
    min_cluster_count = 2
    max_cluster_count = 10
    xmeans_result = x_means_clustering(rng, samples, min_cluster_count, max_cluster_count)

    # Check if the number of clusters identified is 5
    @test length(xmeans_result.centroids) == 3
    @test Set([Set([1, 2, 3]), Set([4, 5, 6]), Set([7, 8, 9])]) == Set(
        [Set(xmeans_result.cluster_indices[1]), 
        Set(xmeans_result.cluster_indices[2]), 
        Set(xmeans_result.cluster_indices[3])]
    )
end

@testset "Large Data Test" begin
    true_centroids = [[1.0, 1.0], [4.0, 4.0], [7.0, 7.0]]
    spread = 0.5
    samples = vcat([generate_cluster(tc, 100, spread) for tc in true_centroids]...)

    xmeans_result = multiple_xmeans(rng, samples, 2, 5, 25)
    @test length(xmeans_result.centroids) == 3
end

@testset "DiscoBinary" begin
    true_centroids = [[0.0, 0.0, 0.0], [2.0, 2.0, 2.0], [4.0, 4.0, 4.0], ]
    spread = 0.1
    samples = vcat([generate_cluster(tc, 3, spread) for tc in true_centroids]...)

    # Run X-Means
    min_cluster_count = 2
    max_cluster_count = 10
    xmeans_result = x_means_clustering(rng, samples, min_cluster_count, max_cluster_count, DiscoBinary())

    # Check if the number of clusters identified is 5
    @test length(xmeans_result.centroids) == 3


end


@testset "Basic" begin
    samples = [rand(3) for _ in 1:100]
    cluster_count = 5
    centroids = kmeans_plus_plus_init(rng, samples, cluster_count)

    @test length(centroids) == cluster_count
    @test all(centroid -> centroid in samples, centroids)

    # Test 2: Empty Samples
    empty_samples = Vector{Float64}[]
    @test_throws ArgumentError kmeans_plus_plus_init(rng, empty_samples, cluster_count)

    # Test 3: Single Sample
    single_sample = [rand(3)]
    @test length(kmeans_plus_plus_init(rng, single_sample, 1)) == 1

    # Test 4: More Clusters Than Samples
    #more_clusters = length(samples) + 1
    #@test_throws ArgumentError kmeans_plus_plus_init(rng, samples, more_clusters)

    # Test 5: Randomness
    centroids_1 = kmeans_plus_plus_init(rng, samples, cluster_count)
    centroids_2 = kmeans_plus_plus_init(rng, samples, cluster_count)
    @test centroids_1 != centroids_2
end

using Test
@testset "Initialization" begin
    # Generate the dataset

    true_centroids = [[0.0, 0.0, 0.0], [1.0, 1.0, 1.0], [2.0, 2.0, 2.0]] # Ensure centroids are distant
    spread = 0.1 # Control the spread around the true centroid
    samples = vcat(generate_cluster(true_centroids[1], 10, spread),
                generate_cluster(true_centroids[2], 10, spread),
                generate_cluster(true_centroids[3], 10, spread))

    # Run KMeans++ Initialization
    cluster_count = 3
    init_centroids = kmeans_plus_plus_init(rng, samples, cluster_count)

    threshold = 3 * spread # A reasonable threshold considering the spread
    @test all(centroid -> is_close_to_any_centroid(centroid, true_centroids, threshold), init_centroids)

end


# Assuming split_cluster and other necessary functions are defined

# Test Case: Splitting Normal Cluster
@testset "Split" begin
    cluster_samples = [rand(3) for _ in 1:20]
    split_centroids = split_cluster(rng, cluster_samples)
    @test length(split_centroids) == 2

    # Test Case: Evaluating and Splitting Clusters
    samples = [rand(rng, 3) for _ in 1:100]
    initial_centroids = kmeans_plus_plus_init(rng, samples, 3)

    # Test Case: Full Clustering Process
    full_clustering_result = get_kmeans_clustering_result(
        rng, samples, 3, initial_centroids; 
        tolerance=0.001, maximum_iterations=500
    )
    @test typeof(full_clustering_result) == KMeansClusteringResult
    @test length(full_clustering_result.centroids) <= 3

end

@testset "Distances" begin
    m1 = [0.8, 0.9]
    m2 = [0.5, 0.4]
    global_averages = [0.6, 0.5]
    tests = float.([
           [0, 1],  # Test 1: s1 fails, s2 succeeds
           [1, 0],  # Test 2: s1 succeeds, s2 fails
           [1, 1],  # Test 3: both succeed
           [0, 0]   # Test 4: both fail
           # Add more tests as needed
       ])
    for test in tests
        println("Test: ", test)
        println("Euclidean Distance to m1: ", squared_euclidean_distance(test, m1))
        println("Euclidean Distance to m2: ", squared_euclidean_distance(test, m2))
        println("DOC-BIN Distance to m1: ", disco_binary_distance(test, m1))
        println("DOC-BIN Distance to m2: ", disco_binary_distance(test, m2))
        println("DOC-AVG Distance to m1: ", disco_average_distance(test, m1, global_averages))
        println("DOC-AVG Distance to m2: ", disco_average_distance(test, m2, global_averages))
        println()
    end

end