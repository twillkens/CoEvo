export perform_clustering, create_informative_matrix, calculate_clustering_qualities, create_derived_matrix, assign_cluster_ids, perform_kmeans_and_get_derived_matrix, simplify_matrix, handle_small_matrix_cases

using ...Matrices.Outcome

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

function create_informative_matrix(matrix::OutcomeMatrix)
    non_zero_row_indices = get_nonzero_row_indices(matrix.data)
    unique_col_indices = get_unique_column_indices(matrix)
    matrix = OutcomeMatrix(
        matrix.id, 
        matrix.row_ids[non_zero_row_indices], 
        matrix.column_ids[unique_col_indices], 
        matrix.data[non_zero_row_indices, unique_col_indices]
    )
    return matrix
end

function perform_clustering(evaluator::DodoTestEvaluator, raw_matrix::OutcomeMatrix)
    filtered_matrix = create_informative_matrix(raw_matrix)
    if length(filtered_matrix.row_ids) == 0
        return deepcopy(raw_matrix), [[id for id in raw_matrix.row_ids]]
    end
    n_clusters = min(evaluator.max_clusters, length(filtered_matrix.row_ids))
    derived_matrix, all_cluster_ids = perform_kmeans_and_get_derived_matrix(filtered_matrix, n_clusters)
    println("N_CLUSTERS = ", length(all_cluster_ids))
    # now create a new outcome matrix that add back the zero rows and ids with n_columns matching the derived_matrix
    data = zeros(Int, length(raw_matrix.row_ids), length(derived_matrix.column_ids))
    for (row_index, id) in enumerate(raw_matrix.row_ids)
        if id in derived_matrix.row_ids
            data[row_index, :] = derived_matrix[id, :]
        end
    end
    matrix = OutcomeMatrix(raw_matrix.id, raw_matrix.row_ids, derived_matrix.column_ids, data)

    return matrix, all_cluster_ids
end