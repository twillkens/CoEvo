
function kmeans_plus_plus_init(samples::Vector{Vector{Float64}}, cluster_count::Int, rng::AbstractRNG)::Vector{Vector{Float64}}
    # Choose the first centroid randomly from the samples
    centroids = [copy(samples[rand(rng, 1:length(samples))])]

    for _ in 2:cluster_count
        distances = Float64[]

        for sample in samples
            # Find the shortest distance from this sample to any existing centroid
            min_distance = minimum([euclidean_distance(sample, centroid) for centroid in centroids])
            push!(distances, min_distance^2)
        end

        # Choose a new centroid randomly, weighted by the square of the distances
        total_distance = sum(distances)
        probabilities = distances / total_distance
        cumulative_probabilities = cumsum(probabilities)
        random_value = rand(rng)
        new_centroid_index = findfirst(x -> x >= random_value, cumulative_probabilities)
        push!(centroids, copy(samples[new_centroid_index]))
    end

    return centroids
end
# Assuming the kmeans_plus_plus_init function and euclidean_distance function are already defined

# Test 1: Basic Functionality
samples = [rand(3) for _ in 1:100]
cluster_count = 5
rng = Random.default_rng()
centroids = kmeans_plus_plus_init(samples, cluster_count, rng)

@test length(centroids) == cluster_count
@test all(centroid -> centroid in samples, centroids)

# Test 2: Empty Samples
empty_samples = Vector{Float64}[]
@test_throws ArgumentError kmeans_plus_plus_init(empty_samples, cluster_count, rng)

# Test 3: Single Sample
single_sample = [rand(3)]
@test length(kmeans_plus_plus_init(single_sample, 1, rng)) == 1

# Test 4: More Clusters Than Samples
more_clusters = length(samples) + 1
@test_throws ArgumentError kmeans_plus_plus_init(samples, more_clusters, rng)

# Test 5: Randomness
centroids_1 = kmeans_plus_plus_init(samples, cluster_count, rng)
centroids_2 = kmeans_plus_plus_init(samples, cluster_count, rng)
@test centroids_1 != centroids_2

using Test

# Generate the dataset
function generate_cluster(centroid, num_points, spread)
    return [centroid + spread * round.(randn(length(centroid)); digits=2) for _ in 1:num_points]
end

true_centroids = [[0.0, 0.0, 0.0], [1.0, 1.0, 1.0], [2.0, 2.0, 2.0]] # Ensure centroids are distant
spread = 0.1 # Control the spread around the true centroid
samples = vcat(generate_cluster(true_centroids[1], 10, spread),
               generate_cluster(true_centroids[2], 10, spread),
               generate_cluster(true_centroids[3], 10, spread))

# Run KMeans++ Initialization
cluster_count = 3
rng = Random.default_rng()
init_centroids = kmeans_plus_plus_init(samples, cluster_count, rng)
println("true_centroids = ", true_centroids)
println("init_centroids = ", init_centroids)

# Test if the initialized centroids are close to the true centroids
function is_close_to_any_centroid(centroid, true_centroids, threshold)
    return any(euclidean_distance(centroid, tc) < threshold for tc in true_centroids)
end

threshold = 2 * spread # A reasonable threshold considering the spread
@test all(centroid -> is_close_to_any_centroid(centroid, true_centroids, threshold), init_centroids)

function split_cluster(cluster_samples::Vector{Vector{Float64}}, rng::AbstractRNG)
    # Using K-means++ initialization for splitting the cluster into two sub-clusters
    return kmeans_plus_plus_init(cluster_samples, 2, rng)
end

function split_and_evaluate_clusters(
    rng::AbstractRNG,
    samples::Vector{Vector{Float64}},
    current_centroids::Vector{Vector{Float64}},
    tolerance::Float64,
    maximum_iterations::Int
)::Vector{Vector{Float64}}
    new_centroids = Vector{Vector{Float64}}()
    for centroid in current_centroids
        # Extract samples belonging to the current cluster
        cluster_samples = [
            s for s in samples if euclidean_distance(s, centroid) == minimum([euclidean_distance(s, c) 
                for c in current_centroids])
        ]


        # If there are not enough samples to split, keep the current centroid
        if length(cluster_samples) < 2
            push!(new_centroids, centroid)
            continue
        end

        # Split the cluster into two
        split_centroids = split_cluster(cluster_samples, rng)

        # Evaluate each split using K-means and calculate BIC
        better_centroid = centroid
        better_bic = -Inf
        for sc in split_centroids
            result = get_kmeans_clustering_result(rng, cluster_samples, 2, [centroid, sc], tolerance=tolerance, maximum_iterations=maximum_iterations)
            if result.bic > better_bic
                better_bic = result.bic
                better_centroid = sc
            end
        end

        push!(new_centroids, better_centroid)
    end

    return new_centroids
end



function x_means_clustering(
    rng::AbstractRNG,
    samples::Vector{Vector{Float64}}, 
    min_cluster_count::Int, 
    max_cluster_count::Int; 
    tolerance::Float64 = 0.001, 
    maximum_iterations::Int = 500
)::KMeansClusteringResult
    # Initialize with min_cluster_count
    centroids = kmeans_plus_plus_init(samples, min_cluster_count, rng)
    best_result = get_kmeans_clustering_result(rng, samples, min_cluster_count, centroids, tolerance=tolerance, maximum_iterations=maximum_iterations)
    best_bic = best_result.bic

    for num_clusters in (min_cluster_count+1):max_cluster_count
        # Attempt to split each cluster and evaluate
        new_centroids = split_and_evaluate_clusters(rng, samples, centroids, tolerance, maximum_iterations)
        
        # Evaluate new clustering
        new_result = get_kmeans_clustering_result(rng, samples, length(new_centroids), new_centroids, tolerance=tolerance, maximum_iterations=maximum_iterations)
        new_bic = new_result.bic

        # Update best result if BIC is improved
        if new_bic > best_bic
            best_bic = new_bic
            best_result = new_result
            centroids = new_centroids # Update centroids for the next iteration
        else
            break # No improvement, stop iterating
        end
    end

    return best_result
end



using Test

# Assuming split_cluster and other necessary functions are defined

# Test Case: Splitting Normal Cluster
cluster_samples = [rand(3) for _ in 1:20]
rng = Random.default_rng()
split_centroids = split_cluster(cluster_samples, rng)
@test length(split_centroids) == 2

# Test Case: Splitting Small Cluster
#small_cluster_samples = [rand(3)]
#split_centroids_small = split_cluster(small_cluster_samples, rng)
#@test isempty(split_centroids_small)


# Test Case: Evaluating and Splitting Clusters
samples = [rand(3) for _ in 1:100]
initial_centroids = kmeans_plus_plus_init(samples, 3, rng)
new_centroids = split_and_evaluate_clusters(rng, samples, initial_centroids, 0.001, 500)
@test length(new_centroids) <= length(initial_centroids) * 2

# Test Case: Full Clustering Process
full_clustering_result = get_kmeans_clustering_result(rng, samples, 3, initial_centroids, tolerance=0.001, maximum_iterations=500)
@test typeof(full_clustering_result) == KMeansClusteringResult
@test length(full_clustering_result.centroids) <= 3


using Test

# Assuming generate_cluster, kmeans_plus_plus_init, and x_means_clustering are defined

# Generate the dataset with 5 clusters
true_centroids = [[0.0, 0.0, 0.0], [2.0, 2.0, 2.0], [4.0, 4.0, 4.0], [6.0, 6.0, 6.0], [8.0, 8.0, 8.0]]
spread = 0.1
samples = vcat([generate_cluster(tc, 10, spread) for tc in true_centroids]...)

# Run X-Means
min_cluster_count = 2
max_cluster_count = 10
xmeans_result = x_means_clustering(rng, samples, min_cluster_count, max_cluster_count)

# Check if the number of clusters identified is 5
@test length(xmeans_result.centroids) == 5

using Test

# ... (previous code for generating dataset and running X-Means)

# Test if each sample is assigned to the correct cluster using cluster_indices
#for (i, true_centroid) in enumerate(true_centroids)
#    cluster_samples = [samples[j] for j in xmeans_result.cluster_indices[i]]
#
#    #for sample in samples[((i-1)*10+1):(i*10)]
#    #    @test sample in cluster_samples
#    #end
#end

