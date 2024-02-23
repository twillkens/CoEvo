export perform_kmeans_and_get_derived_matrix, handle_small_matrix_cases, simplify_matrix, calculate_clustering_qualities, create_derived_matrix, assign_cluster_ids

using ...Matrices.Outcome
using Clustering


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
        println("matrix = ", matrix)
        throw(ArgumentError("Failed to find a non-degenerate clustering. Consider adjusting max_clusters or input data."))
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

    columns_clustering = get_best_clustering(matrix, max_clusters, on=:columns)
    # Create derived matrix from centroids
    matrix = create_derived_matrix(matrix, columns_clustering.centers)
    all_columns_same = all(all(matrix.data[:, 1] .== matrix.data[:, j]) for j in 2:size(matrix.data, 2))
    all_rows_same = all(all(matrix.data[1, :] .== matrix.data[i, :]) for i in 2:size(matrix.data, 1))
    
    # If conditions for simplifying the matrix are met or only one cluster is desired
    if all_columns_same || all_rows_same || max_clusters < 2
        return simplify_matrix(matrix)
    end
    rows_clustering = get_best_clustering(matrix, max_clusters, on=:rows)

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