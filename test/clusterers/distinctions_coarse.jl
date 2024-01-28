using DataStructures # Assuming this package provides SortedDict

using DataStructures # Assuming this package provides SortedDict

using CoEvo.Concrete.Evaluators.NSGAII


# Example usage
evaluators = SortedDict{Int, Vector{Float64}}(
    1 => [0, 0, 1],
    2 => [1, 0, 1],
    3 => [0, 1, 0]
)
outcome_dict = individual_tests_to_individual_distinctions(evaluators)
println("outcome_dict = ", outcome_dict)

o = create_outcomes_and_distinctions(evaluators)
println("o = ", o)



## Example usage
#G = [0 1 0; 0 0 1; 1 1 0]
#outcome_matrix = create_distinction_outcome_matrix(G)
#println("outcome_matrix = ", outcome_matrix)
#
#G = [1 1 1 1 ; 0 0 1 1 ; 1 0 0 0]
#outcome_matrix = create_distinction_outcome_matrix(G)
#println("outcome_matrix = ", outcome_matrix)
#