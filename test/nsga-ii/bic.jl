function bayesian_information_criterion(samples::Vector{Vector{Float64}}, centroids::Vector{Vector{Float64}}, clusters::Vector{Vector{Int}})
    K = length(centroids)  # Number of clusters
    N = sum(length(cluster) for cluster in clusters)  # Total number of data points
    dimension = length(samples[1])  # Dimensionality of data points
    println("K: ", K)
    println("N: ", N)
    println("dimension: ", dimension)

    sigma_sqrt = 0.0  # Estimation of the noise variance

    # Calculate the sum of squared distances from each point to its cluster centroid
    for (index_cluster, cluster) in enumerate(clusters)
        centroid = centroids[index_cluster]
        for index_point in cluster
            point = samples[index_point]
            sigma_sqrt += sum((point[i] - centroid[i])^2 for i in 1:dimension)
        end
    end
    println("sigma_sqrt: ", sigma_sqrt)

    # Avoid division by zero
    if N > K
        sigma_sqrt /= (N - K)
        println("sigma_sqrt: ", sigma_sqrt)
        p = (K - 1) + dimension * K + 1  # Number of free parameters
        println("p: ", p)

        # Calculate BIC for each cluster and sum them
        scores = Float64[]
        for cluster in clusters
            n = length(cluster)
            println("n: ", n)
            sigma_multiplier = sigma_sqrt <= 0.0 ? -Inf : dimension * 0.5 * log(sigma_sqrt)
            arg1 = n * log(n / N)
            arg2 = n * dimension * 0.5 * log(2 * π)
            arg3 = n * sigma_multiplier
            arg4 = (n - K) * 0.5
            println("arg1: $arg1, arg2: $arg2, arg3: $arg3, arg4: $arg4")
            println("sigma_multiplier: ", sigma_multiplier)
            L = n * log(n / N) - n * 0.5 * log(2 * π) - n * sigma_multiplier - (n - K) * 0.5

            #L = n * log(n / N) - n * dimension * 0.5 * log(2 * π) - n * dimension * 0.5 * log(sigma_sqrt) - (n - K) * 0.5
            println("L: ", L)
            push!(scores, L - p * 0.5 * log(N))
        end
        println("scores: ", scores)

        return sum(scores)
    else
        return -Inf
    end
end

samples = [[1, 2], [1.5, 2.5], [3, 4], [3.5, 4.5]]
centroids = [[1.0, 2.0], [3.0, 4.0]]
clusters = [[1, 2], [3, 4]]
bic = bayesian_information_criterion(samples, centroids, clusters)
print("BIC:", bic)
# # Test 1: Basic functionality with well-separated clusters
# samples = [[1.0, 2.0], [1.5, 2.5], [10.0, 10.0], [10.5, 10.5], [50.0, 50.0], [51.0, 52.0]]
# centroids = [[1.25, 2.25], [10.25, 10.25], [50.5, 51.0]]
# clusters = [[1, 2], [3, 4], [5, 6]]
# bic = bayesian_information_criterion(samples, centroids, clusters)
# println("BIC for well-separated clusters: ", bic)
# 
# # Test 2: Overfitting with more clusters than necessary
# samples = [[1.0, 2.0], [1.5, 2.5], [2.0, 3.0]]
# centroids = [[1.0, 2.0], [1.5, 2.5], [2.0, 3.0]]  # Each point is its own cluster
# clusters = [[1], [2], [3]]
# bic = bayesian_information_criterion(samples, centroids, clusters)
# println("BIC for overfitting scenario: ", bic)
# clusters = [[0, 1], [2, 3]]
# # Test 3: Single cluster
# samples = [[1.0, 2.0], [1.5, 2.5], [2.0, 3.0]]
# centroids = [[1.5, 2.5]]  # All points in one cluster
# clusters = [[1, 2, 3]]
# bic = bayesian_information_criterion(samples, centroids, clusters)
# println("BIC for a single cluster: ", bic)
# 
# # Test 4: More clusters than points
# samples = [[1.0, 2.0]]
# centroids = [[1.0, 2.0], [2.0, 3.0]]  # More centroids than points
# clusters = [[1], Int[]]
# bic = bayesian_information_criterion(samples, centroids, clusters)
# println("BIC for more clusters than points: ", bic)
# 
# # Test 5: Random data
# using Random
# 
# Random.seed!(123)  # Seed for reproducibility
# samples = [float.(rand(1:100, 2)) for _ in 1:50]
# centroids = [float.(rand(1:100, 2)) for _ in 1:5]  # Random centroids
# clusters = [rand(1:50, 10) for _ in 1:5]   # Random clusters
# bic = bayesian_information_criterion(samples, centroids, clusters)
# println("BIC for random data: ", bic)
# 