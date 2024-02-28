export create_fallback_clustering, get_best_clustering

using ...Matrices.Outcome
using StatsBase
using LinearAlgebra
using Distributed

function create_fallback_clustering(X::AbstractMatrix{<:AbstractFloat}, on::Symbol=:rows)
   unique_patterns = unique(on == :rows ? eachrow(X) : eachcol(X))

   n = size(X, on == :rows ? 1 : 2)
   k = length(unique_patterns)
   d = size(X, on == :rows ? 2 : 1)
   assignments = zeros(Int, n)
   costs = zeros(Float64, n)
   counts = zeros(Int, k)

   for (index, pattern) in enumerate(on == :rows ? eachrow(X) : eachcol(X))
       # Corrected the lambda function for findfirst
       cluster_index = findfirst(entry -> entry == pattern, unique_patterns)
       assignments[index] = cluster_index
   end

   centers = zeros(Float64, d, k)
   for i = 1:k
       cluster_indices = findall(idx -> assignments[idx] == i, 1:n)  # Corrected the use of findall
       if isempty(cluster_indices)
	   continue
       end
       cluster_entries = on == :rows ? X[cluster_indices, :] : X[:, cluster_indices]

       # Ensure that center calculation is appropriate for both row and column vectors
       center = mean(cluster_entries, dims=on == :rows ? 1 : 2)
       if on == :rows
	   centers[:, i] = vec(center)  # Flatten the center for row-wise clustering
       else
	   centers[:, i] = center[:]  # Ensure center is correctly oriented for column-wise clustering
       end

       for j in cluster_indices
	   entry = on == :rows ? X[j, :] : vec(X[:, j])  # Ensure entry is a vector for norm calculation
	   costs[j] = norm(entry - vec(center))  # Use vec to ensure dimension compatibility
       end
       counts[i] = length(cluster_indices)
   end

   totalcost = sum(costs)
   wcounts = counts / sum(counts)
   iterations = 1
   converged = true

   return KmeansResult(centers, assignments, costs, counts, wcounts, totalcost, iterations, converged)
end

function get_best_clustering(matrix::OutcomeMatrix, max_clusters::Int; on::Symbol=:rows)
    check_length = on == :rows ? length(matrix.row_ids) : length(matrix.column_ids)
    max_clusters = min(max_clusters, check_length - 1)
    X = on == :rows ? transpose(matrix.data) : matrix.data

    # Split the work of clustering across workers
    # Each worker handles clustering for a different number of clusters
    #clustering_tasks = [(@spawnat w kmeans(X, k)) for (w, k) in zip(cycle(workers()), 2:max_clusters)]
    workers_ids = workers()
    num_workers = length(workers_ids)
    clustering_tasks = [
        (@spawnat workers_ids[(i % num_workers) + 1] kmeans(X, k)) 
        for (i, k) in enumerate(2:max_clusters)
    ]
    clusterings = [fetch(task) for task in clustering_tasks]


    best_quality = -Inf
    best_clustering = nothing

    for clustering in clusterings
        # Assuming calculate_clustering_qualities and quality checks are defined elsewhere and are serial
        if maximum(clustering.counts) == size(X, 2) || minimum(clustering.counts) < 2
            continue
        end

        quality = calculate_clustering_qualities(X, [clustering])

        if quality[1] > best_quality
            best_quality = quality[1]
            best_clustering = clustering
        end
    end

    if isnothing(best_clustering) && check_length > 1
        # Fallback clustering is a serial operation but could be adapted if necessary
        return create_fallback_clustering(X, on)
    elseif isnothing(best_clustering)
        error("Failed to find a non-degenerate clustering. Consider adjusting max_clusters or input data.")
    end

    return best_clustering
end
