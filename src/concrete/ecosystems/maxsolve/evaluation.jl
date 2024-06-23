export create_performance_matrix, make_sum_scalar_matrix, perform_competitive_fitness_sharing
export evaluate_standard, zero_out_duplicate_rows, evaluate_advanced

using ...Matrices.Outcome: OutcomeMatrix, make_full_distinction_matrix


function make_sum_scalar_matrix(matrix::OutcomeMatrix)
    average_scalar_matrix = OutcomeMatrix{Float64}(matrix.id, matrix.row_ids, ["sum"])
    for i in matrix.row_ids
        average_scalar_matrix[i, "sum"] = sum(matrix[i, :])
    end
    return average_scalar_matrix
end

function perform_competitive_fitness_sharing(matrix::OutcomeMatrix)
    # Calculate the sum of each column and then take the inverse
    test_defeats_inverses = 1.0 ./ sum(matrix.data, dims=1)

    # Create a new OutcomeMatrix with the same dimensions
    new_matrix = OutcomeMatrix{Float64}(matrix.id, matrix.row_ids, matrix.column_ids)

    # Use broadcasting to divide each column element by the corresponding test defeat sum
    new_matrix.data = matrix.data .* test_defeats_inverses

    return new_matrix
end


function evaluate_standard(matrix::OutcomeMatrix)
    scalar_matrix = make_sum_scalar_matrix(matrix)
    return scalar_matrix
end

function zero_out_duplicate_rows(matrix::OutcomeMatrix{T, U, V, W}) where {T, U, V, W}
    matrix = deepcopy(matrix)
    unique_rows = Dict{Vector{W}, Vector{U}}()
    for id in matrix.row_ids
        row = matrix[id, :]
        if !(row in keys(unique_rows))
            unique_rows[row] = [id]
        else
            push!(unique_rows[row], id)
        end
    end
    ids_to_keep = Set(rand(ids) for ids in values(unique_rows))
    #println("IDs to keep = ", ids_to_keep)
    for id in matrix.row_ids
        if !(id in ids_to_keep)
            for column_id in matrix.column_ids
                matrix[id, column_id] = W(0)
            end
        end
    end
    return matrix
end


function evaluate_advanced(
    matrix::OutcomeMatrix{T, U, V, W}, 
    outcome_weight::Float64 = 3.0,
    distinction_weight::Float64 = 1.0
) where {T, U, V, W}
    #println("-----")
    #println("Matrix = ", matrix)
    #matrix = zero_out_duplicate_rows(matrix)
    #println("Zeroed out duplicate rows = ", matrix)
    competitive_matrix = perform_competitive_fitness_sharing(matrix)
    #println("Competitive matrix = ", competitive_matrix)
    sum_competitive_matrix = make_sum_scalar_matrix(competitive_matrix)
    #println("Sum competitive matrix = ", sum_competitive_matrix)
    distinction_matrix = make_full_distinction_matrix(matrix)
    #println("Distinction matrix = ", distinction_matrix)
    competitive_distinction_matrix = perform_competitive_fitness_sharing(distinction_matrix)
    #println("Competitive distinction matrix = ", competitive_distinction_matrix)
    sum_competitive_distinction_matrix = make_sum_scalar_matrix(competitive_distinction_matrix)
    #println("Sum competitive distinction matrix = ", sum_competitive_distinction_matrix)
    #scores = Pair{U, Float64}[]
    advanced_matrix = OutcomeMatrix{Float64}(matrix.id, matrix.row_ids, ["advanced_score"])
    for id in matrix.row_ids
        outcome_score = sum_competitive_matrix[id, "sum"] * outcome_weight
        distinction_score = sum_competitive_distinction_matrix[id, "sum"] * distinction_weight
        score = outcome_score + distinction_score
        advanced_matrix[id, "advanced_score"] = score
    end
    #sort!(scores, by=x->x[2], rev=true)
    return advanced_matrix
end

function evaluate_dodo(
    ecosystem::Ecosystem, raw_matrix::OutcomeMatrix, state::State, species_id::String
)
    # for this experiment we do not need to filter the matrix
    filtered_matrix = deepcopy(raw_matrix)
    derived_matrix, all_cluster_ids = get_derived_matrix(filtered_matrix)
    if length(all_cluster_ids) == 0
        all_cluster_ids = [[id for id in raw_matrix.row_ids]]
    end
    reconstructed_filtered_matrix = reconstruct_matrix(raw_matrix, filtered_matrix)
    reconstructed_derived_matrix = reconstruct_matrix(raw_matrix, derived_matrix)
    records = create_records(
        ecosystem, raw_matrix, reconstructed_filtered_matrix, reconstructed_derived_matrix
    )
    #cluster_leader_ids = get_cluster_leader_ids(all_cluster_ids, records)
    #println("CLUSTER_LEADER_IDS = ", cluster_leader_ids)

    #farthest_first_ids = farthest_first_traversal(reconstructed_derived_matrix, cluster_leader_ids)
    cluster_leader_ids = Int[]
    farthest_first_ids = Int[]

    evaluation = NewDodoEvaluation(
        id = species_id,
        cluster_leader_ids = cluster_leader_ids,
        farthest_first_ids = farthest_first_ids,
        raw_matrix = raw_matrix,
        filtered_matrix = reconstructed_filtered_matrix,
        matrix = reconstructed_derived_matrix,
        records = records
    )
    #print_info(raw_matrix, filtered_matrix, derived_matrix, records, all_cluster_ids)
    return evaluation
end

function get_doc_records(
    ecosystem::Ecosystem, raw_matrix::OutcomeMatrix, state::State, species_id::String
)


end

function farthest_first_traversal(
    matrix::OutcomeMatrix, initial_visited::Vector{U}, n_points::Int = length(matrix.row_ids)
) where U
    # Initialize a boolean array to keep track of visited nodes, using row_ids
    #println("row ids = ", matrix.row_ids)
    #println("initial ids = ", initial_visited)
    visited = falses(length(matrix.row_ids))
    for id in initial_visited
        idx = findfirst(==(id), matrix.row_ids)
        visited[idx] = true
    end

    search_order = copy(initial_visited)

    # Preallocate a distance matrix to store precomputed distances
    distances = fill(-Inf, n_points, n_points)

    while sum(visited) < n_points
        farthest_node = nothing
        max_distance = -Inf

        for i in 1:n_points
            if visited[i]
                continue
            end

            min_distance = Inf
            for j in findall(visited)
                if distances[i, j] == -Inf
                    # Computing the distance between row i and row j
                    distance = sum(matrix.data[i, :] .!= matrix.data[j, :])
                    distances[i, j] = distance
                    distances[j, i] = distance  # Symmetric property
                else
                    distance = distances[i, j]
                end

                if distance < min_distance
                    min_distance = distance
                end
            end

            if min_distance > max_distance
                max_distance = min_distance
                farthest_node = i
            end
        end

        visited[farthest_node] = true
        push!(search_order, matrix.row_ids[farthest_node])
    end

    # Filter out the initial_visited to return only the new sequence
    return filter(x -> !(x in initial_visited), search_order)
end