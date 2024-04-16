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
    competitive_matrix = perform_competitive_fitness_sharing(matrix)
    sum_competitive_matrix = make_sum_scalar_matrix(competitive_matrix)
    distinction_matrix = make_full_distinction_matrix(matrix)
    competitive_distinction_matrix = perform_competitive_fitness_sharing(distinction_matrix)
    sum_competitive_distinction_matrix = make_sum_scalar_matrix(competitive_distinction_matrix)
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

function evaluate_dodo(
    ecosystem::Ecosystem, raw_matrix::OutcomeMatrix, state::State, species_id::String
)
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
    print_info(raw_matrix, filtered_matrix, derived_matrix, records, all_cluster_ids)
    return evaluation
end
