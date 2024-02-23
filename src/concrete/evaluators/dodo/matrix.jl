export perform_kmeans_and_get_derived_matrix, handle_small_matrix_cases, simplify_matrix, calculate_clustering_qualities, create_derived_matrix, assign_cluster_ids

using ...Matrices.Outcome
using Clustering
using Random
using StatsBase
using Distributed


#function get_best_clustering(matrix::OutcomeMatrix, max_clusters::Int; on::Symbol=:rows)
#    check_length = on == :rows ? length(matrix.row_ids) : length(matrix.column_ids)
#    max_clusters = min(max_clusters, check_length)
#    X = on == :rows ? transpose(matrix.data) : matrix.data  # Transpose to have correct dimensions for clustering
#    clusterings = kmeans.(Ref(X), 2:max_clusters)
#    qualities = calculate_clustering_qualities(X, clusterings)
#    best_clustering_index = argmax(qualities)
#    best_clustering = clusterings[best_clustering_index]
#    return best_clustering
#end

#function get_best_clustering(matrix::OutcomeMatrix, max_clusters::Int; on::Symbol=:rows)
#    check_length = on == :rows ? length(matrix.row_ids) : length(matrix.column_ids)
#    
#    # Ensure max_clusters is within bounds
#    max_clusters = min(max_clusters, check_length - 1)
#    
#    # Prepare data based on clustering direction
#    X = on == :rows ? transpose(matrix.data) : matrix.data
#    
#    # Initialize quality tracking
#    best_quality = -Inf
#    best_clustering = nothing
#    
#    # Iterate through possible number of clusters
#    for k in 2:max_clusters
#        clustering = kmeans(X, k)
#        
#        # Skip quality calculation if clustering is degenerate
#        if maximum(clustering.counts) == size(X, 2) || minimum(clustering.counts) < 2
#            continue
#        end
#        
#        # Calculate quality for current clustering
#        quality = calculate_clustering_qualities(X, [clustering])
#        
#        # Update best clustering if current is better
#        if quality[1] > best_quality
#            best_quality = quality[1]
#            best_clustering = clustering
#        end
#    end
#    
#    # Handle case where no suitable clustering was found
#    if isnothing(best_clustering)
#        println("matrix = ", matrix)
#        throw(ArgumentError("Failed to find a non-degenerate clustering. Consider adjusting max_clusters or input data."))
#    end
#    
#    return best_clustering
#end
#
#
using LinearAlgebra: norm

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
    
    # Ensure max_clusters is within bounds
    max_clusters = min(max_clusters, check_length - 1)
    
    # Prepare data based on clustering direction
    X = on == :rows ? transpose(matrix.data) : matrix.data
    
    # Initialize quality tracking
    best_quality = -Inf
    best_clustering = nothing
    
    # Iterate through possible number of clusters
    for k in 2:max_clusters
        clustering = kmeans(X, k)
        
        # Skip quality calculation if clustering is degenerate
        if maximum(clustering.counts) == size(X, 2) || minimum(clustering.counts) < 2
            continue
        end
        
        # Calculate quality for current clustering
        quality = calculate_clustering_qualities(X, [clustering])
        
        # Update best clustering if current is better
        if quality[1] > best_quality
            best_quality = quality[1]
            best_clustering = clustering
        end
    end
    
    # Handle case where no suitable clustering was found
    if isnothing(best_clustering)
        if check_length > 1
            # Call to create a fallback clustering
            return create_fallback_clustering(X, on)
        else
            println("matrix = ", matrix)
            throw(ArgumentError("Failed to find a non-degenerate clustering. Consider adjusting max_clusters or input data."))
        end
    end
    
    return best_clustering
end

function get_best_clustering_parallel(matrix::OutcomeMatrix, max_clusters::Int; on::Symbol=:rows)
    check_length = on == :rows ? length(matrix.row_ids) : length(matrix.column_ids)
    max_clusters = min(max_clusters, check_length - 1)
    X = on == :rows ? transpose(matrix.data) : matrix.data

    # Split the work of clustering across workers
    # Each worker handles clustering for a different number of clusters
    #clustering_tasks = [(@spawnat w kmeans(X, k)) for (w, k) in zip(cycle(workers()), 2:max_clusters)]
    workers_ids = workers()
num_workers = length(workers_ids)
clustering_tasks = [(@spawnat workers_ids[(i % num_workers) + 1] kmeans(X, k)) for (i, k) in enumerate(2:max_clusters)]


    best_quality = -Inf
    best_clustering = nothing

    for task in clustering_tasks
        clustering = fetch(task)

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



function perform_kmeans_and_get_derived_matrix(matrix::OutcomeMatrix, max_clusters::Int)
    # Early exit conditions
    if length(matrix.row_ids) == 0
        return (OutcomeMatrix(0, Vector{Int}(), Vector{Int}(), Matrix{Float64}(undef, 0, 0)), [])
    elseif length(matrix.row_ids) <= 2
        # Handle cases with 1 or 2 rows separately as clustering is not needed
        return handle_small_matrix_cases(matrix)
    end

    # Preprocessing to check if all rows or columns are the same
    all_columns_same = all(all(matrix.data[:, 1] .== matrix.data[:, j]) for j in 2:size(matrix.data, 2))
    all_rows_same = all(all(matrix.data[1, :] .== matrix.data[i, :]) for i in 2:size(matrix.data, 1))
    
    # If conditions for simplifying the matrix are met or only one cluster is desired
    if all_columns_same || all_rows_same || max_clusters < 2
        return simplify_matrix(matrix)
    end

    #columns_clustering = get_best_clustering(matrix, max_clusters, on=:columns)
    columns_clustering = get_best_clustering_parallel(matrix, max_clusters, on=:columns)
    # Create derived matrix from centroids
    matrix = create_derived_matrix(matrix, columns_clustering.centers)
    all_columns_same = all(all(matrix.data[:, 1] .== matrix.data[:, j]) for j in 2:size(matrix.data, 2))
    all_rows_same = all(all(matrix.data[1, :] .== matrix.data[i, :]) for i in 2:size(matrix.data, 1))
    
    # If conditions for simplifying the matrix are met or only one cluster is desired
    if all_columns_same || all_rows_same || max_clusters < 2
        return simplify_matrix(matrix)
    end
    #rows_clustering = get_best_clustering(matrix, max_clusters, on=:rows)
    rows_clustering = get_best_clustering_parallel(matrix, max_clusters, on=:rows)

    # Assign cluster IDs to row IDs
    cluster_ids = assign_cluster_ids(matrix.row_ids, rows_clustering.assignments)
    n_rows_expected, n_columns_expected = size(matrix.data)
    if length(matrix.row_ids) != n_rows_expected || length(matrix.column_ids) != n_columns_expected
        throw(ArgumentError("Derived matrix and cluster IDs have inconsistent dimensions"))
    end

    return (matrix, cluster_ids)
end

function handle_small_matrix_cases(matrix::OutcomeMatrix)
    row_count = length(matrix.row_ids)
    
    if row_count == 0
        # No rows to cluster
        return (OutcomeMatrix(0, Vector{Int}(), Vector{Int}(), Matrix{Float64}(undef, 0, 0)), [])
    elseif row_count == 1
        # A single row forms a cluster by itself
        return (matrix, [[first(matrix.row_ids)]])
    else  # row_count == 2
        id_1, id_2 = matrix.row_ids
        if all(matrix.data[1, :] .== matrix.data[2, :])
            # Rows are identical, group together
            return (matrix, [[id_1, id_2]])
        else
            # Rows differ, separate clusters
            return (matrix, [[id_1], [id_2]])
        end
    end
end


function simplify_matrix(matrix::OutcomeMatrix)
    # Simplify the matrix based on your specific logic for all columns/rows being the same
    # Placeholder return statement:
    summed_column = sum(matrix.data[:, 1])
    derived_data = fill(summed_column, (size(matrix.data, 1), 1))
    simplified_matrix = OutcomeMatrix(matrix.id, matrix.row_ids, ["derived_sum"], derived_data)
    return (simplified_matrix, [matrix.row_ids])
end

function calculate_clustering_qualities(X, clusterings)
    qualities = Float64[]
    for clustering in clusterings
        push!(qualities, clustering_quality(X, clustering, quality_index=:silhouettes))
    end
    return qualities
end

function create_derived_matrix(matrix::OutcomeMatrix, centroids)
    derived_matrix = OutcomeMatrix(
        "derived",
        matrix.row_ids,
        ["derived_$i" for i in 1:size(centroids, 2)],
        #transpose(centroids)  # Transpose centroids to fit matrix.data format
        #collect(transpose(centroids))
        centroids
    )
    return derived_matrix
end

function assign_cluster_ids(row_ids, assignments)
    cluster_dict = Dict{Int, Vector{Int}}()
    for (row_index, assignment) in enumerate(assignments)
        push!(get!(cluster_dict, assignment, []), row_ids[row_index])
    end
    return values(cluster_dict) |> collect
end

#function perform_kmeans_search(matrix::OutcomeMatrix, max_clusters::Int)
#    if length(matrix.row_ids) == 0
#        return []
#    elseif length(matrix.row_ids) == 1
#        return [[first(matrix.row_ids)]]
#    elseif length(matrix.row_ids) == 2
#        id_1, id_2 = matrix.row_ids
#        if matrix[id_1, :] == matrix[id_2, :]
#            return [[id_1, id_2]]
#        else
#            return [[id_1], [id_2]]
#        end
#    else
#        all_rows_same = all(all(matrix.data[1, :] .== matrix.data[i, :]) for i in 2:size(matrix.data, 1))
#        if all_rows_same
#            return [matrix.row_ids]
#        end
#        max_clusters = min(max_clusters, length(matrix.row_ids) - 1)
#        X = transpose(matrix.data)
#        clusterings = kmeans.(Ref(X), 2:max_clusters)
#        qualities = Float64[]
#        for clustering in clusterings
#            try 
#                push!(qualities, clustering_quality(X, clustering, quality_index=:silhouettes))
#            catch e
#                println("clustering = ", clustering)
#                throw(e)
#            end
#        end
#        best_clustering_index = argmax(qualities)
#        best_clustering = clusterings[best_clustering_index]
#        clustering_dict = Dict{Int, Vector{Int}}()
#        for (row_index, assignment) in enumerate(best_clustering.assignments)
#            if haskey(clustering_dict, assignment)
#                push!(clustering_dict[assignment], matrix.row_ids[row_index])
#            else
#                clustering_dict[assignment] = [matrix.row_ids[row_index]]
#            end
#        end
#        cluster_ids = collect(values(clustering_dict))
#        return cluster_ids
#    end
#end
