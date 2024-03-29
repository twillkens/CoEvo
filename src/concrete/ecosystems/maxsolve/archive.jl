using ...Matrices.Outcome

function maxsolve(matrix::OutcomeMatrix{T, U, V, W}, archive_size::Int) where {T, U, V, W}
    number_solved = Dict{U, Int}()
    println("----IN MAXSOLVE")
    println("matrix size = ", size(matrix.data))
    for id in matrix.row_ids
        number_solved[id] = sum(matrix[id, :])
    end
    for i in eachindex(matrix.row_ids)
        current = matrix.row_ids[i]
        start = i + 1
        for j in start:length(matrix.row_ids)
            other = matrix.row_ids[j]
            if matrix[current, :] == matrix[other, :]
                number_solved[other] = 0
            end
        end
    end
    n_pick = min(archive_size, length(number_solved))
    number_solved = sort(collect(number_solved), by=x->(x[2], rand()), rev=true)[1:n_pick]
    println("number_solved = ", number_solved, " out of ", length(matrix.column_ids))
    matrix = filter_rows(matrix, [x[1] for x in number_solved])
    #println("filtered_matrix_maxsolve = ", matrix)
    tests_to_check = V[]
    for test_id in matrix.column_ids
        for learner_id in matrix.row_ids
            if matrix[learner_id, test_id] == 1
                push!(tests_to_check, test_id)
                break
            end
        end
    end
    #sort!(tests_to_check, rev=true)
    #println("tests_to_check = ", tests_to_check)
    println("length(tests_to_check) = ", length(tests_to_check))
    selected_tests = V[]
    while length(tests_to_check) > 0
        test_id = pop!(tests_to_check)
        #println("-----")
        #println("matrix[:, $test_id] = ", matrix[:, test_id])
        test_is_redundant = false
        for other_test_id in tests_to_check
             #println("matrix[:, $other_test_id] = ", matrix[:, other_test_id])
            if matrix[:, test_id] == matrix[:, other_test_id]
                test_is_redundant = true
                break
            end
        end
        if !test_is_redundant
            push!(selected_tests, test_id)
        end
    end
    println("selected_tests = ", length(selected_tests))
    if length(selected_tests) == 0
        push!(selected_tests, matrix.column_ids[1])
    end
    matrix = filter_columns(matrix, selected_tests)
    println("filtered_matrix_maxsolve = ", size(matrix.data))
    return matrix
end

#function maxsolve_reverse(matrix::OutcomeMatrix{T, U, V, W}, archive_size::Int) where {T, U, V, W}
#    number_solved = Dict{U, Int}()
#    for id in matrix.row_ids
#        number_solved[id] = sum(matrix[id, :])
#    end
#    for i in eachindex(matrix.row_ids)
#        current = matrix.row_ids[i]
#        start = i + 1
#        for j in start:length(matrix.row_ids)
#            other = matrix.row_ids[j]
#            if matrix[current, :] == matrix[other, :]
#                number_solved[other] = 0
#            end
#        end
#    end
#    n_pick = min(archive_size, length(number_solved))
#    number_solved = sort(collect(number_solved), by=x->(x[2], rand()), rev=true)[1:n_pick]
#    println("number_solved = ", number_solved, " out of ", length(matrix.column_ids))
#    matrix = filter_rows(matrix, [x[1] for x in number_solved])
#    #println("filtered_matrix_maxsolve = ", matrix)
#    tests_to_check = V[]
#    for test_id in matrix.column_ids
#        for learner_id in matrix.row_ids
#            if matrix[learner_id, test_id] == 1
#                push!(tests_to_check, test_id)
#                break
#            end
#        end
#    end
#    #sort!(tests_to_check, rev=true)
#    #println("tests_to_check = ", tests_to_check)
#    selected_tests = V[]
#    while length(tests_to_check) > 0
#        test_id = pop!(tests_to_check)
#        println("test id = ", test_id, " genes = ", matrix[:, test_id])
#        #println("-----")
#        #println("matrix[:, $test_id] = ", matrix[:, test_id])
#        test_is_redundant = false
#        for other_test_id in tests_to_check
#             #println("matrix[:, $other_test_id] = ", matrix[:, other_test_id])
#            if matrix[:, test_id] == matrix[:, other_test_id]
#                test_is_redundant = true
#                break
#            end
#        end
#        if !test_is_redundant
#            push!(selected_tests, test_id)
#        end
#    end
#    if length(selected_tests) == 0
#        push!(selected_tests, matrix.column_ids[1])
#    end
#    matrix = filter_columns(matrix, selected_tests)
#    println("filtered_matrix_maxsolve = ", size(matrix.data))
#    return matrix
#end