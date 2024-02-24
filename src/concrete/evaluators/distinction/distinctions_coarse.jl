export individual_tests_to_individual_distinctions, create_distinction_outcome_matrix, dict_to_matrix, matrix_to_dict
export create_outcomes_and_distinctions

using DataStructures # Assuming this package provides SortedDict

function dict_to_matrix(dict::SortedDict{Int, Vector{Float64}})
    num_evaluators = length(dict)
    num_learners = length(first(values(dict)))

    G = Matrix{Float64}(undef, num_learners, num_evaluators)

    #id_to_index = Dict{Int, Int}()
    #for (index, evaluator_id) in enumerate(keys(dict))
    #    id_to_index[evaluator_id] = index
    #end

    for (index, results) in enumerate(values(dict))
        #println("results_$index = $results")
        G[:, index] = results
    end

    return G
end

function create_distinction_outcome_matrix(G::Matrix)
    num_learners = size(G, 1)
    num_evaluators = size(G, 2)
    # Only half the pairs are needed since (i, j) and (j, i) are essentially the same comparison
    outcome_matrix = zeros(Int, num_evaluators, num_learners * (num_learners - 1) ÷ 2)
    #println("size_outcome_matrix = ", size(outcome_matrix))

    for evaluator in 1:num_evaluators
        col = 1
        for i in 1:num_learners
            for j in i+1:num_learners  # Start from i+1 to avoid self-play and repeat comparisons
                outcome_matrix[evaluator, col] = G[i, evaluator] != G[j, evaluator] ? 1 : 0
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

function individual_tests_to_individual_distinctions(individual_tests::SortedDict{Int, Vector{Float64}})
    try
        G = dict_to_matrix(individual_tests)
        outcome_matrix = create_distinction_outcome_matrix(G)
        individual_distinctions = matrix_to_dict(outcome_matrix, collect(keys(individual_tests)))
        return individual_distinctions
    catch e
        println("individual_tests = $individual_tests")
        throw(e)
    end

end

function create_outcomes_and_distinctions(individual_tests::SortedDict{Int, Vector{Float64}})
    G = dict_to_matrix(individual_tests)
    outcome_matrix = create_distinction_outcome_matrix(G)
    distinctions = matrix_to_dict(outcome_matrix, collect(keys(individual_tests)))
    outcomes_and_distinctions = SortedDict{Int, Vector{Float64}}()
    for (id, tests) in individual_tests
        outcomes_and_distinctions[id] = [tests; distinctions[id]]
    end
    return outcomes_and_distinctions
end

function competitive_fitness_sharing!(E::SortedDict{Int, Vector{Float64}})
    O = dict_to_matrix(E)
    index_sums = sum(O, dims=2)
    for (id, outcomes) in E
        for index in eachindex(outcomes)
            if outcomes[index] == 1
                outcomes[index] = 1 / index_sums[index]
            end
        end
        E[id] = [sum(outcomes)]
    end
end