
using Random
using ...Matrices.Outcome: OutcomeMatrix

function get_identical_vector_sets(matrix::Matrix; on::Symbol)::Vector{Vector{Int}}
    vectors = if on == :rows
        [vec for vec in eachrow(matrix)]
    elseif on == :columns
        [vec for vec in eachcol(matrix)]
    else
        error("Invalid option for 'on': $on. Use :rows or :columns.")
    end

    vec_dict = Dict{Vector{Float64}, Vector{Int}}()
    for (index, vec) in enumerate(vectors)
        vec_key = float.(vec)
        if haskey(vec_dict, vec_key)
            push!(vec_dict[vec_key], index)
        else
            vec_dict[vec_key] = [index]
        end
    end

    return collect(values(vec_dict))
end

function get_filtered_indices(
    matrix::Matrix; 
    filter_zero_rows::Bool = true, 
    filter_zero_columns::Bool = true, 
    filter_duplicate_rows::Bool = true, 
    filter_duplicate_columns::Bool = true, 
    rng::AbstractRNG = Random.GLOBAL_RNG
) 
    row_indices = 1:size(matrix, 1)
    col_indices = 1:size(matrix, 2)
    
    # Filter zero rows
    if filter_zero_rows
        row_indices = filter(i -> !all(matrix[i, :] .== 0), row_indices)
    end
    
    # Filter zero columns
    if filter_zero_columns
        col_indices = filter(j -> !all(matrix[:, j] .== 0), col_indices)
    end
    
    # Filter and randomly select from duplicate rows
    if filter_duplicate_rows
        identical_row_sets = get_identical_vector_sets(matrix, on=:rows)
        identical_row_sets = [
            [x for x in row_set if x in row_indices] for row_set in identical_row_sets
        ]
        row_indices = sort(
            [rand(rng, row_set) for row_set in identical_row_sets if length(row_set) > 0]
        )
    end

    # Filter and randomly select from duplicate columns
    if filter_duplicate_columns
        identical_col_sets = get_identical_vector_sets(matrix, on=:columns)
        identical_col_sets = [
            [x for x in col_set if x in col_indices] for col_set in identical_col_sets
        ]
        col_indices = sort(
            [rand(rng, col_set) for col_set in identical_col_sets if length(col_set) > 0]
        )
    end
    
    return (row_indices, col_indices)
end

function get_filtered_matrix(matrix::OutcomeMatrix; kwargs...)
    #non_zero_row_indices = get_nonzero_row_indices(matrix.data)
    row_indices, column_indices = get_filtered_indices(matrix.data, kwargs...)
    matrix = OutcomeMatrix(
        matrix.id, 
        matrix.row_ids[row_indices], 
        matrix.column_ids[column_indices], 
        matrix.data[row_indices, column_indices]
    )
    return matrix
end