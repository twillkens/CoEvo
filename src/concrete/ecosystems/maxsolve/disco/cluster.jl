export create_derived_matrix, assign_cluster_ids
export perform_kmeans_and_get_derived_matrix, simplify_matrix, handle_small_matrix_cases

using ...Matrices.Outcome

function handle_small_matrix_cases(matrix::OutcomeMatrix)
    row_count = length(matrix.row_ids)
    
    if row_count == 0
        # No rows to cluster
        return (OutcomeMatrix(0, Vector{Int}(), Vector{Int}(), Matrix{Float64}(undef, 0, 0)), [])
    elseif row_count == 1
        # A single row forms a cluster by itself
        return (matrix, [[first(matrix.row_ids)]])
    elseif row_count == 2
        id_1, id_2 = matrix.row_ids
        if matrix.data[1, :] == matrix.data[2, :]
            # Rows are identical, group together
            println("SMALL ROWS IDENTICAL")
            return (matrix, [[id_1, id_2]])
        else
            println("SMALL ROWS DIFFER")
            # Rows differ, separate clusters
            return (matrix, [[id_1], [id_2]])
        end
    else
        error("Unexpected number of rows in matrix: $row_count")
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

#function assign_cluster_ids(row_ids, assignments)
#    cluster_dict = Dict{Int, Vector{Int}}()
#    #println("ROW_IDS = ", row_ids)
#    #println("ASSIGNMENTS = ", assignments)
#    for (row_index, assignment) in enumerate(assignments)
#        push!(get!(cluster_dict, assignment, []), row_ids[row_index])
#    end
#    return values(cluster_dict) |> collect
#end

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

    println("CLUSTERING ON COLUMNS")

    columns_clustering = get_best_clustering(matrix, max_clusters, on=:columns)
    # Create derived matrix from centroids
    matrix = create_derived_matrix(matrix, columns_clustering.centers)
    all_columns_same = all(all(matrix.data[:, 1] .== matrix.data[:, j]) for j in 2:size(matrix.data, 2))
    all_rows_same = all(all(matrix.data[1, :] .== matrix.data[i, :]) for i in 2:size(matrix.data, 1))
    
    # If conditions for simplifying the matrix are met or only one cluster is desired
    if all_columns_same || all_rows_same || max_clusters < 2
        return simplify_matrix(matrix)
    end

    println("CLUSTERING ON ROWS")
    rows_clustering = get_best_clustering(matrix, max_clusters, on=:rows)

    # Assign cluster IDs to row IDs
    n_rows_expected, n_columns_expected = size(matrix.data)
    if length(matrix.row_ids) != n_rows_expected || length(matrix.column_ids) != n_columns_expected
        throw(ArgumentError("Derived matrix and cluster IDs have inconsistent dimensions"))
    end
    #println("CLUSTER_IDS = ", cluster_ids)
    cluster_ids = assign_cluster_ids(matrix.row_ids, rows_clustering.assignments)

    return matrix, cluster_ids
end

function get_derived_matrix(matrix::OutcomeMatrix, max_clusters::Int = 5)
    n_clusters = min(max_clusters, length(matrix.row_ids))
    derived_matrix, all_cluster_ids = perform_kmeans_and_get_derived_matrix(matrix, n_clusters)
    return derived_matrix, all_cluster_ids
end
