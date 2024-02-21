using CoEvo.Concrete.Clusterers.XMeans
#using CoEvo.Concrete.Clusterers.GlobalKMeans
using Plots

function generate_cluster_pairs(num_clusters::Int)
    # Initialize an empty array to hold the sample points
    samples = Vector{Vector{Float64}}()

    # Distance between the centers of clusters to ensure they are recognized as separate
    cluster_distance = 10.0

    # Generate `num_clusters` pairs of points
    for i in 1:num_clusters
        # Calculate the center of the current cluster
        center_x = i * cluster_distance
        center_y = i * cluster_distance

        # Generate two points for each cluster, slightly offset from the center
        point1 = [center_x + rand(), center_y + rand()]
        point2 = [center_x - rand(), center_y - rand()]
        point3 = [center_x - rand() * 2, center_y - rand() * 2]

        # Append the points to the samples array
        push!(samples, point1)
        push!(samples, point2)
        push!(samples, point3)
    end

    return samples
end

function plot_kmeans_result(result::KMeansClusteringResult)
    colors = distinguishable_colors(length(result.centroids)) # Assign a unique color to each cluster
    scatter(legend = false, title = "KMeans Clustering Result, BIC: $(round(result.bic, digits=2))")

    # Plot each cluster with its samples
    for (i, cluster) in enumerate(result.clusters)
        xs = [sample[1] for sample in cluster] # Extract the first dimension
        ys = [sample[2] for sample in cluster] # Extract the second dimension
        scatter!(xs, ys, color = colors[i], label = "")
    end

    # Plot centroids
    centroid_xs = [centroid[1] for centroid in result.centroids]
    centroid_ys = [centroid[2] for centroid in result.centroids]
    scatter!(centroid_xs, centroid_ys, color = :black, shape = :star5, label = "Centroids", markersize = 8)

    xlabel!("Dimension 1")
    ylabel!("Dimension 2")
end

function generate_complex_dataset(num_clusters::Int, points_per_cluster::Int, seed::Int = 123)
    Random.seed!(seed) # Ensure reproducibility
    samples = Vector{Vector{Float64}}()

    for i in 1:num_clusters
        # Define the center of each cluster
        center = rand(1:50, 2) * i

        # Different variance for each cluster
        #variance = rand(1:3) * i
        variance = 1.0

        # Generate points for each cluster
        for _ in 1:points_per_cluster
            point = center + randn(2) * variance
            push!(samples, point)
        end
    end

    # Add noise
    #for _ in 1:num_clusters * points_per_cluster * 0.1 # 10% noise
    #    push!(samples, rand(1:500, 2))
    #end

    return samples
end
function vecvec_to_matrix(x)
    X = zeros(length(first(x)), length(x))
    for (i, y) in enumerate(x)
        X[:, i] = y
    end
    return X
end

using Random
using Clustering

function perform_kmeans_search(matrix::OutcomeMatrix, max_clusters::Int)
    if length(matrix.row_ids) == 0
        return []
    elseif length(matrix.row_ids) == 1
        return [[first(matrix.row_ids)]]
    elseif length(matrix.row_ids) == 2
        id_1, id_2 = matrix.row_ids
        if matrix[id_1, :] == matrix[id_2, :]
            return [[id_1, id_2]]
        else
            return [[id_1], [id_2]]
        end
    else
        max_clusters = min(max_clusters, length(matrix.row_ids) - 1)
        X = transpose(matrix.data)
        clusterings = kmeans.(Ref(X), 2:max_clusters)
        qualities = clustering_quality.(Ref(X), clusterings, quality_index=:silhouettes)
        best_clustering_index = argmax(qualities)
        best_clustering = clusterings[best_clustering_index]
        clustering_dict = Dict{Int, Vector{Int}}()
        for (row_index, assignment) in enumerate(best_clustering.assignments)
            if haskey(clustering_dict, assignment)
                push!(clustering_dict[assignment], matrix.row_ids[row_index])
            else
                clustering_dict[assignment] = [matrix.row_ids[row_index]]
            end
        end
        cluster_ids = collect(values(clustering_dict))
        return cluster_ids
    end
end

samples = OutcomeMatrix(generate_cluster_pairs(10))
#result = x_means_nosplits(Random.GLOBAL_RNG, samples, 1, 20; info_criterion = "AIC")
#result = x_means_clustering(Random.GLOBAL_RNG, samples, 1, 20; info_criterion = "AIC")
#result = multiple_xmeans(Random.GLOBAL_RNG, samples, 1, 20, 10; info_criterion = "AIC")
#result = get_fast_global_clustering_result(Random.GLOBAL_RNG, samples; max_clusters = 20)
#plot_kmeans_result(result)
#plot_kmeans_result(do_kmeans(samples, 10); )