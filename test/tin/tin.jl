using CoEvo.Abstract
using CoEvo.Interfaces
using CoEvo.Concrete.Evaluators.NSGAII
using CoEvo.Concrete.Matrices.Outcome
using StatsBase

include("sillhouette_kmeans.jl")



learner_matrix = OutcomeMatrix(
    "L", 
    ["W", "X", "Y", "Z"],
    ["A", "B", "C", "D"], 
    Bool[
        1 1 1 0; 
        1 1 0 0; 
        1 0 0 0; 
        0 0 1 1
    ]
)

test_matrix = OutcomeMatrix(
    "T", 
    ["A", "B", "C", "D"],
    ["W", "X", "Y", "Z"], 
    Bool[
        0 0 0 1; 
        0 0 1 1; 
        0 1 1 0; 
        1 1 1 0
    ]
)

function print_matrix_types(matrix::OutcomeMatrix)
    println("Original matrix")
    println(matrix)
    competitive_matrix = perform_competitive_fitness_sharing(matrix)
    println("Competive matrix")
    println(competitive_matrix)

    sum_competitive_matrix = make_sum_scalar_matrix(competitive_matrix)
    println("Sum competitive matrix")
    println(sum_competitive_matrix)


    distinction_matrix = make_full_distinction_matrix(matrix)
    println("Distinction matrix")
    println(distinction_matrix)

    competitive_distinction_matrix = perform_competitive_fitness_sharing(distinction_matrix)
    println("Competitive distinction matrix")
    println(competitive_distinction_matrix)

    sum_competitive_distinction_matrix = make_sum_scalar_matrix(competitive_distinction_matrix)

    println("Sum competitive distinction matrix")
    println(sum_competitive_distinction_matrix)
end



print_matrix_types(learner_matrix)

maxsolve_matrix = maxsolve(learner_matrix, 2)
println("Maxsolve_matrix = ", maxsolve_matrix)


selected_standard = select_standard(learner_matrix, 2)
println("Selected standard = ", selected_standard)
selected_advanced = select_advanced(learner_matrix, 2)
println("Selected advanced = ", selected_advanced)

clustering = get_best_clustering(learner_matrix, 2)
println("Clustering = ", clustering)



learner_matrix = OutcomeMatrix(
    "L", 
    ["W", "X", "Y", "Z"],
    ["A", "B", "C", "D"], 
    Bool[
        1 1 1 0; 
        1 1 0 0; 
        1 0 0 0; 
        0 0 1 1
    ]
)

order = farthest_first_search(learner_matrix, ["X"])
println("Farthest first search order = ", order)

# Creating a larger, more interpretable OutcomeMatrix
learner_matrix = OutcomeMatrix(
    "InformativeMatrix", 
    ["Node1", "Node2", "Node3", "Node4", "Node5"],
    ["FeatureA", "FeatureB", "FeatureC", "FeatureD", "FeatureE"], 
    Bool[
        1 1 1 0 0;  # Node1
        1 1 1 0 0;  # Node2
        0 0 0 1 1;  # Node3
        0 0 0 1 1;  # Node4
        1 0 0 1 0;  # Node5 - Distinct from others
    ]
)

order = farthest_first_search(learner_matrix, ["Node1"])
println("Farthest first search order = ", order)
clustering = get_best_clustering(learner_matrix, 3)
println("Clustering = ", clustering)

# Creating a larger, more interpretable OutcomeMatrix
learner_matrix = OutcomeMatrix(
    "compare-on-all-example", 
    ["a1", "a2", "a3", "b1", "b2", "b3", "c1", "c2", "c3"],
    ["x1", "x2", "x3", "y1", "y2", "y3", "z1", "z2", "z3"],
    Bool[
        1 0 0 0 0 0 0 0 0;  # a1
        1 1 0 0 0 0 0 0 0;  # a2
        1 1 1 0 0 0 0 0 0;  # a3
        1 0 0 1 0 0 0 0 0;  # b1
        1 1 0 1 1 0 0 0 0;  # b2
        1 1 1 1 1 1 0 0 0;  # b3
        1 0 0 1 0 0 1 0 0;  # c1
        1 1 0 1 1 0 1 1 0;  # c2
        1 1 1 1 1 1 1 1 1;  # c3
    ]
)
maxsolve_matrix = maxsolve(learner_matrix, 3)
println("Maxsolve_matrix = ", maxsolve_matrix)


#learner_outcomes = [
#    # first 
#    SimpleOutcome("L", "W", "A", 1),
#    SimpleOutcome("L", "W", "B", 1),
#    SimpleOutcome("L", "W", "C", 1),
#    SimpleOutcome("L", "W", "D", 0),
#
#    # second
#    SimpleOutcome("L", "X", "A", 1),
#    SimpleOutcome("L", "X", "B", 1),
#    SimpleOutcome("L", "X", "C", 0),
#    SimpleOutcome("L", "X", "D", 0),
#
#    # third
#    SimpleOutcome("L", "Y", "A", 1),
#    SimpleOutcome("L", "Y", "B", 0),
#    SimpleOutcome("L", "Y", "C", 0),
#    SimpleOutcome("L", "Y", "D", 0),
#
#    # fourth
#    SimpleOutcome("L", "Z", "A", 0),
#    SimpleOutcome("L", "Z", "B", 0),
#    SimpleOutcome("L", "Z", "C", 1),
#    SimpleOutcome("L", "Z", "D", 1),
#]
#
#test_outcomes = [
#    # first 
#    SimpleOutcome("T", "A", "W", 0),
#    SimpleOutcome("T", "A", "X", 0),
#    SimpleOutcome("T", "A", "Y", 0),
#    SimpleOutcome("T", "A", "Z", 1),
#
#    # second
#    SimpleOutcome("T", "B", "W", 0),
#    SimpleOutcome("T", "B", "X", 0),
#    SimpleOutcome("T", "B", "Y", 1),
#    SimpleOutcome("T", "B", "Z", 1),
#
#    # third
#    SimpleOutcome("T", "C", "W", 0),
#    SimpleOutcome("T", "C", "X", 1),
#    SimpleOutcome("T", "C", "Y", 1),
#    SimpleOutcome("T", "C", "Z", 0),
#
#    # fourth
#    SimpleOutcome("T", "D", "W", 1),
#    SimpleOutcome("T", "D", "X", 1),
#    SimpleOutcome("T", "D", "Y", 1),
#    SimpleOutcome("T", "D", "Z", 0),
#]
#
#outcomes = [learner_outcomes; test_outcomes]
#matrix = create_performance_matrix("L", outcomes)
#println(matrix)
#
#learner_outcomes = [
#    # first 
#    SimpleOutcome("A", 1, 4, [0.0, 0.0, 0.0]),
#    SimpleOutcome("A", 1, 5, [0.0, 0.0, 0.0]),
#    SimpleOutcome("A", 1, 6, [1.0, 1.0, 0.0]),
#
#    # second
#    SimpleOutcome("A", 2, 4, [1.0, 0.0, 0.0]),
#    SimpleOutcome("A", 2, 5, [0.0, 1.0, 1.0]),
#    SimpleOutcome("A", 2, 6, [0.0, 1.0, 0.0]),
#
#    # third
#    SimpleOutcome("A", 3, 4, [0.0, 0.0, 0.0]),
#    SimpleOutcome("A", 3, 5, [0.0, 1.0, 0.0]),
#    SimpleOutcome("A", 3, 6, [0.0, 0.0, 0.0]),
#]
#
#test_outcomes = [
#    # first 
#    SimpleOutcome("B", 4, 1, [1.0, 1.0, 1.0]),
#    SimpleOutcome("B", 4, 2, [1.0, 1.0, 1.0]),
#    SimpleOutcome("B", 4, 3, [0.0, 0.0, 1.0]),
#
#    # second
#    SimpleOutcome("B", 5, 1, [0.0, 1.0, 1.0]),
#    SimpleOutcome("B", 5, 2, [1.0, 0.0, 0.0]),
#    SimpleOutcome("B", 5, 3, [1.0, 0.0, 1.0]),
#
#    # third
#    SimpleOutcome("B", 6, 1, [1.0, 1.0, 1.0]),
#    SimpleOutcome("B", 6, 2, [1.0, 0.0, 1.0]),
#    SimpleOutcome("B", 6, 3, [1.0, 1.0, 1.0]),
#]
#all_outcomes = [learner_outcomes; test_outcomes]
#
#matrix = create_performance_matrix("A", all_outcomes)
#println(matrix)
#
##OutcomeMatrix with ID: A
##           4      5      6
##   1 |    1.0    1.0    3.0
##   2 |    2.0    3.0    2.0
##   3 |    1.0    2.0    1.0
#
#average_scalar_matrix = make_average_scalar_matrix(matrix)
#println(average_scalar_matrix)
#
##OutcomeMatrix with ID: A
##           average
##   1 |    1.6666666666666667
##   2 |    2.3333333333333335
##   3 |    1.3333333333333333
#
#
#distinction_matrix = make_full_distinction_matrix(matrix)
#println(distinction_matrix)
#
##OutcomeMatrix with ID: A
##      (1, 2) (1, 3) (2, 1) (2, 3) (3, 1) (3, 2)
##   1 |    0.0    0.0    1.0    1.0    0.0    0.0
##   2 |    0.0    0.0    1.0    1.0    1.0    0.0
##   3 |    1.0    1.0    0.0    1.0    0.0    0.0
#
#competitive_matrix = perform_competitive_fitness_sharing(matrix)
#println(competitive_matrix)
#
##OutcomeMatrix with ID: A
##           4      5      6
##   1 |    1.0    1.0    3.0
##   2 |    2.0    3.0    2.0
##   3 |    1.0    2.0    1.0
#struct MultiOutcome{T, U, R <: Real} <: Result
#    species_id::String
#    solution_id::T
#    test_id::U
#    outcome::R
#end
#function create_performance_matrix(species_id::String, outcomes::Vector{<:MultiOutcome})
#    filtered_outcomes = filter(x -> x.species_id == species_id, outcomes)
#    ids = sort(unique([outcome.individual_id for outcome in filtered_outcomes]))
#    other_ids = sort(unique([outcome.other_entity_id for outcome in filtered_outcomes]))
#    payoff_matrix = OutcomeMatrix(species_id, ids, other_ids)
#    for other_id in other_ids
#        records = NSGAIIRecord[]
#        other_outcomes = filter(x -> x.other_entity_id == other_id, filtered_outcomes)
#        for id in ids 
#            outcome_against_other = first(filter(x -> x.individual_id == id, other_outcomes)) 
#            record = NSGAIIRecord(
#                id = id, other_id = other_id, outcomes = outcome_against_other.payoffs
#            )
#            push!(records, record)
#        end
#        records = nsga_sort!(records)
#        maximum_rank = maximum([record.rank for record in records])
#        for record in records
#            value = maximum_rank - record.rank + 1
#            payoff_matrix[record.id, record.other_id] = value
#        end
#    end
#    return payoff_matrix
#end
#