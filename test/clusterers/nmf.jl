using NMF
using DataStructures # Assuming this package provides SortedDict
using Random

function calculate_G_prime(G::Matrix{Float64}, W::Matrix{Float64}, H::Matrix{Float64})
    m, r = size(W) # m candidates, r features
    _, n = size(H) # n tests
    G_prime = zeros(m, r)

    for i in 1:m
        for j in 1:r
            # Find the tests that are solved by candidate i
            solved_tests = [k for k in 1:n if G[i, k] == 2.0] # 3.0 because 2.0 in original + 1
            # Sum the factors in H that correspond to the solved tests
            sum_factors = sum(H[j, k] for k in solved_tests)
            # Compute the search objective
            G_prime[i, j] = W[i, j] * sum_factors
        end
    end

    return G_prime
end

function create_interaction_matrix(indiv_tests::SortedDict{Int, Vector{Float64}})
    preprocessed_tests = SortedDict{Int, Vector{Float64}}()
    for (id, test_vector) in indiv_tests
        preprocessed_tests[id] = [x + 1 for x in test_vector]
    end

    # Convert preprocessed_tests to matrix
    
    # Transpose each vector and vertically concatenate them to form a matrix
    interaction_matrix = vcat([transpose(vector) for vector in values(preprocessed_tests)]...)

    return interaction_matrix
end

function get_derived_tests_nmf(
    rng::AbstractRNG, 
    indiv_tests::SortedDict{Int, Vector{Float64}},
    num_factors::Int = 3 # Optional parameter for the number of factors
)
    # Preprocess indiv_tests to add 1 to each entry
    interaction_matrix = create_interaction_matrix(indiv_tests)
    println("interaction_matrix = ", interaction_matrix)

    # set the seed for reproducibility
    Random.seed!(abs(rand(rng, Int)))
    # Perform NMF
    result = nnmf(interaction_matrix, num_factors, init = :random, alg = :multmse)

    # Extract W and H matrices from NMF result
    W = result.W
    H = result.H
    println("W = ", W)
    println("H = ", H)


    # Calculate G' using W and H
    G_prime = calculate_G_prime(interaction_matrix, W, H)
    println("G_prime = ", G_prime)

    # Convert G' back into SortedDict format
    derived_tests = SortedDict{Int, Vector{Float64}}()
    for (id, row) in zip(keys(indiv_tests), eachrow(G_prime))
        derived_tests[id] = collect(row)
    end

    return derived_tests
end