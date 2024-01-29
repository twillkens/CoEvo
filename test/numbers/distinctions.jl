using DataStructures # Assuming this package provides SortedDict

using DataStructures # Assuming this package provides SortedDict

using CoEvo.Concrete.Evaluators.Distinction
using CoEvo.Interfaces


# Example usage
outcome_matrix = SortedDict{Int, Vector{Float64}}(
    1 => [0, 0, 1],
    2 => [1, 0, 1],
    3 => [0, 1, 0]
)

o = make_distinction_matrix(outcome_matrix)
println("o = ", o)

o = make_outcome_and_distinction_matrix(outcome_matrix)
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