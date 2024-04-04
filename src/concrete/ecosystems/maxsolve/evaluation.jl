export create_performance_matrix, make_sum_scalar_matrix, perform_competitive_fitness_sharing
export evaluate_standard, zero_out_duplicate_rows, evaluate_advanced, farthest_first_search

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
    matrix = zero_out_duplicate_rows(matrix)
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
    scores = Pair{U, Float64}[]
    advanced_matrix = OutcomeMatrix{Float64}(matrix.id, matrix.row_ids, ["advanced_score"])
    for id in matrix.row_ids
        outcome_score = sum_competitive_matrix[id, "sum"] * outcome_weight
        distinction_score = sum_competitive_distinction_matrix[id, "sum"] * distinction_weight
        score = outcome_score + distinction_score
        advanced_matrix[id, "advanced_score"] = score
    end
    sort!(scores, by=x->x[2], rev=true)
    return advanced_matrix
end

function farthest_first_search(
    matrix::OutcomeMatrix, initial_visited::Vector, n_points::Int = length(matrix.row_ids)
)
    # Initialize the set of visited nodes with the initial_visited entries
    visited = Set(initial_visited)
    #println("Visited = ", visited)
    
    # Initialize a list to store the search order
    search_order = copy(initial_visited)
    #println("N_POINTS = ", n_points)
    #println("Search order at start = ", search_order)

    # Continue the loop until all nodes are visited
    while length(visited) < n_points
        # Initialize variables to store the farthest node and its distance
        farthest_node = nothing
        max_distance = -Inf  # Use -Inf to initialize the max distance

        for row_id in matrix.row_ids
            # Skip if the node is already visited
            if row_id in visited
                continue
            end

            # Initialize the minimum distance for the current node
            min_distance = Inf  # Initialize to positive infinity

            # Calculate the minimum distance from the current node to any node in the visited set
            for visited_id in visited
                # Calculate the distance (here, assuming Hamming distance for binary data)
                #distance = sum(matrix[row_id, :] .!= matrix[visited_id, :])
                distance = sqrt(sum((matrix[row_id, :] - matrix[visited_id, :]).^2))

                # Update the minimum distance if the current distance is smaller
                if distance < min_distance
                    min_distance = distance
                end
            end

            # Update the farthest node if the minimum distance is greater than the current maximum distance
            if min_distance > max_distance
                max_distance = min_distance
                farthest_node = row_id
            end
        end

        # Add the farthest node to the visited set and the search order
        #println("Farthest node = ", farthest_node, " length_visited = ", length(visited))
        push!(visited, farthest_node)
        push!(search_order, farthest_node)
    end
    #println("Search order at end = ", search_order)
    farthest_first = collect(setdiff(search_order, initial_visited))
    #println("Farthest first = ", farthest_first)

    return farthest_first
end

function evaluate_dodo(
    ecosystem::Ecosystem, raw_matrix::OutcomeMatrix, state::State, species_id::String
)
    #results = filter_results_by_cohort(evaluator, species, results, state)
    #println("RAW_MATRIX = ", raw_matrix)
    filtered_matrix = get_filtered_matrix(raw_matrix)
    #println("FILTERED_MATRIX = ", filtered_matrix)
    #filtered_matrix = deepcopy(raw_matrix)
    derived_matrix, all_cluster_ids = get_derived_matrix(filtered_matrix)
    if length(all_cluster_ids) == 0
        all_cluster_ids = [[id for id in raw_matrix.row_ids]]
    end
    println("DERIVED_MATRIX = ", derived_matrix)
    println("ALL_CLUSTER_IDS = ", all_cluster_ids)
    reconstructed_filtered_matrix = reconstruct_matrix(raw_matrix, filtered_matrix)
    reconstructed_derived_matrix = reconstruct_matrix(raw_matrix, derived_matrix)
    records = create_records(
        ecosystem, raw_matrix, reconstructed_filtered_matrix, reconstructed_derived_matrix
    )
    cluster_leader_ids = get_cluster_leader_ids(all_cluster_ids, records)
    println("CLUSTER_LEADER_IDS = ", cluster_leader_ids)
    n_farthest_points = min(5, length(reconstructed_derived_matrix.row_ids)) #- length(cluster_leader_ids)

    farthest_first_ids = farthest_first_search(reconstructed_derived_matrix, cluster_leader_ids, n_farthest_points)
    println("FARTHEST_FIRST_POINTS = ", farthest_first_ids)
    new_parent_ids = [cluster_leader_ids; farthest_first_ids]
    println("NEW_PARENT_IDS = ", new_parent_ids)
    if length(new_parent_ids) != 5
        println("ERROR: Not enough parents to evaluate")
    end

    evaluation = NewDodoEvaluation(
        id = species_id,
        new_parent_ids = new_parent_ids,
        raw_matrix = raw_matrix,
        filtered_matrix = reconstructed_filtered_matrix,
        matrix = reconstructed_derived_matrix,
        records = records
    )
    print_info(raw_matrix, filtered_matrix, derived_matrix, records, all_cluster_ids)
    return evaluation
    #return new_parent_ids
end
