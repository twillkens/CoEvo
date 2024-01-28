using DataStructures # Assuming this package provides SortedDict

function dict_to_matrix(dict::SortedDict{Int, Vector{Float64}})
    num_evaluators = length(dict)
    num_learners = length(first(values(dict)))

    G = Matrix{Float64}(undef, num_learners, num_evaluators)

    for (evaluator_id, results) in dict
        G[:, evaluator_id] = results
    end

    return G
end

function create_outcome_matrix(G::Matrix)
    num_learners = size(G, 1)
    num_evaluators = size(G, 2)
    outcome_matrix = zeros(Int, num_evaluators, num_learners^2)

    for evaluator in 1:num_evaluators
        col = 1
        for i in 1:num_learners
            for j in 1:num_learners
                if i != j
                    outcome_matrix[evaluator, col] = G[i, evaluator] > G[j, evaluator] ? 1 : 0
                end
                col += 1
            end
        end
    end

    return outcome_matrix
end

function matrix_to_dict(matrix::Matrix, keys::Vector{Int})
    dict = SortedDict{Int, Vector{Float64}}()
    for (i, key) in enumerate(keys)
        dict[key] = matrix[i, :]
    end
    return dict
end

function evaluators_to_outcome_dict(evaluators::SortedDict{Int, Vector{Float64}})
    G = dict_to_matrix(evaluators)
    outcome_matrix = create_outcome_matrix(G)
    outcome_dict = matrix_to_dict(outcome_matrix, collect(keys(evaluators)))
    return outcome_dict
end

# Example usage
evaluators = SortedDict{Int, Vector{Float64}}(
    1 => [0, 0, 1],
    2 => [1, 0, 1],
    3 => [0, 1, 0]
)
outcome_dict = evaluators_to_outcome_dict(evaluators)
println("outcome_dict = ", outcome_dict)


# Example usage
G = [0 1 0; 0 0 1; 1 1 0]
outcome_matrix = create_outcome_matrix(G)
println("outcome_matrix = ", outcome_matrix)

G = [1 1 1 1 ; 0 0 1 1 ; 1 0 0 0]
outcome_matrix = create_outcome_matrix(G)
println("outcome_matrix = ", outcome_matrix)


E = SortedDict{Int, Vector{Float64}}(
    1 => [1, 1, 1, 1, 0, 1],
    2 => [1, 0, 1, 0, 1, 0],
    3 => [0, 1, 1, 1, 1, 0],
    4 => [0, 0, 0, 0, 0, 1]
)

function competitive_fitness_sharing!(E::SortedDict{Int, Vector{Float64}})
    O = dict_to_matrix(E)
    index_sums = sum(O, dims=2)
    for (id, outcomes) in E
        for index in eachindex(outcomes)
            if outcomes[index] == 1
                outcomes[index] = 1 / index_sums[index]
            end
        end
    end
end

function competitive_fitness_sharing!(
    population_outcomes::SortedDict{Int, Vector{Float64}}, archive_outcomes::SortedDict{Int, Vector{Float64}}
)
    temp_dict = merge(population_outcomes, archive_outcomes)
    competitive_fitness_sharing!(temp_dict)
end

E = evaluators_to_outcome_dict(E)
E = competitive_fitness_sharing(E)
println("done")
