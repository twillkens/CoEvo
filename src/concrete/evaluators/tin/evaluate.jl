using ....Abstract
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ...Criteria

function create_records(
    evaluator::TinEvaluator,
    species::AbstractSpecies,
    raw_matrix::OutcomeMatrix,
    filtered_matrix::OutcomeMatrix,
    matrix::OutcomeMatrix
)
    I = typeof(species.population[1])
    records = TinRecord{I}[]
    for id in matrix.row_ids
        record = TinRecord(
            id = id, 
            individual = species[id],
            raw_outcomes = raw_matrix[id, :], 
            filtered_outcomes = filtered_matrix[id, :],
            outcomes = matrix[id, :]
        )
        push!(records, record)
    end
    criterion = evaluator.maximize ? Maximize() : Minimize()
    sorted_records = nsga_sort!(
        records, criterion, evaluator.function_minimums, evaluator.function_maximums
    )
    return sorted_records
end

function create_records(
    evaluator::TinEvaluator,
    species::AbstractSpecies,
    matrix::OutcomeMatrix
)
    records = create_records(evaluator, species, deepcopy(matrix), deepcopy(matrix), matrix)
    return records
end

function get_raw_matrix(
    evaluator::TinEvaluator, species::AbstractSpecies, results::Vector{<:Result}
)
    objective = evaluator.objective
    if objective == "performance"
        raw_matrix = OutcomeMatrix(species.population, results)
    elseif objective == "distinction"
        raw_matrix = make_distinction_matrix(species.population, results)
    else
        error("Objective $objective not recognized")
    end
    return raw_matrix
end

function reconstruct_matrix(raw_matrix::OutcomeMatrix, filtered_matrix::OutcomeMatrix)
    filtered_data = zeros(Float64, length(raw_matrix.row_ids), length(filtered_matrix.column_ids))
    for (row_index, id) in enumerate(raw_matrix.row_ids)
        if id in filtered_matrix.row_ids
            filtered_data[row_index, :] = filtered_matrix[id, :]
        end
    end
    filtered_matrix = OutcomeMatrix(
        raw_matrix.id, raw_matrix.row_ids, filtered_matrix.column_ids, filtered_data
    )
    return filtered_matrix
end

function get_high_rank_records(cluster_ids::Vector{Int}, records::Vector{<:TinRecord})
    cluster_records = [record for record in records if record.id in cluster_ids]
    if length(cluster_records) != length(cluster_ids)
        println("CLUSTER_RECORDS = ", [record.id for record in cluster_records])
        println("CLUSTER_IDS = ", cluster_ids)
        error("Cluster records and cluster ids do not match")
    end
    highest_rank = first(cluster_records).rank
    high_rank_records = [record for record in cluster_records if record.rank == highest_rank]
    return high_rank_records
end


function get_cluster_leader_id(
    species::AbstractSpecies, cluster_ids::Vector{Int}, records::Vector{<:TinRecord}
)
    high_rank_records = get_high_rank_records(cluster_ids, records)
    parent_records = [
        record for record in high_rank_records if record.individual in species.parents
    ]
    other_records = [record for record in high_rank_records if !(record in parent_records)]
    chosen_record = length(other_records) > 0 ? rand(other_records) : rand(parent_records)
    id = chosen_record.id
    return id
end

function get_cluster_leader_ids(
    species::AbstractSpecies, 
    all_cluster_ids::Vector{Vector{Int}}, 
    records::Vector{<:TinRecord}
)
    leader_ids = [
        get_cluster_leader_id(species, cluster_ids, records) for cluster_ids in all_cluster_ids
    ]
    return leader_ids
end

function print_info(
    evaluator::TinEvaluator, 
    raw_matrix::OutcomeMatrix, 
    filtered_matrix::OutcomeMatrix, 
    derived_matrix::OutcomeMatrix, 
    records::Vector{<:TinRecord}, 
    all_cluster_ids::Vector{Vector{Int}}
)
    println("--------EVALUATOR_$(evaluator.id)-----")
    println("CLUSTER_SIZES = ", [length(cluster) for cluster in all_cluster_ids])
    println("SIZE_RAW_MATRIX = ", size(raw_matrix.data))
    println("SIZE_FILTERED_MATRIX = ", size(filtered_matrix.data))
    println("SIZE_DERIVED_MATRIX = ", size(derived_matrix.data))
    tag = evaluator.objective == "performance" ? "FILTERED_OUTCOMES" : "FILTERED_DISTINCTIONS"
    println("$tag = ", [Int(sum(record.filtered_outcomes)) for record in records])
end

function get_other_species(species::AbstractSpecies, state::State)
    other_species = first(
        filter(other_species -> other_species.id != species.id, state.ecosystem.all_species)
    )
    return other_species
end

function get_cohort_ids(species::AbstractSpecies, cohort_string::String)
    cohort_symbol = Symbol(cohort_string)
    cohort = getfield(species, cohort_symbol)
    ids = Set([individual.id for individual in cohort])
    return ids
end

function filter_results_by_cohort(
    evaluator::TinEvaluator, 
    species::AbstractSpecies, 
    results::Vector{R}, 
    state::State
) where R <: Result
    if state.generation == 1
        return results
    end
    filtered_results = R[]
    other_species = get_other_species(species, state)
    ids_to_use = Set{Int}()
    for cohort_string in evaluator.other_species_comparison_cohorts
        cohort_ids = get_cohort_ids(other_species, cohort_string)
        union!(ids_to_use, cohort_ids)
    end

    for result in results
        individual_ids = result.match.individual_ids
        if any(id in ids_to_use for id in individual_ids)
            push!(filtered_results, result)
        end
    end
    return filtered_results
end

function get_hillclimber_parent_ids(species::AbstractSpecies, matrix::OutcomeMatrix)
    new_parent_ids = Int[]
    for child in species.children
        parent = species[child.parent_id]
        child_outcomes = matrix[child.id, :]
        parent_outcomes = matrix[parent.id, :]
        parent_dominates_child = dominates(Maximize(), parent_outcomes, child_outcomes)
        if parent_dominates_child
            push!(new_parent_ids, parent.id)
        else
            child_on_lower_level = sum(child_outcomes) < sum(parent_outcomes)
            if child_on_lower_level
                push!(new_parent_ids, parent.id)
            else
                push!(new_parent_ids, child.id)
            end
        end
    end
    return new_parent_ids
end

function evaluate(
    evaluator::TinEvaluator, 
    species::AbstractSpecies,
    results::Vector{<:Result},
    state::State
)
    results = filter_results_by_cohort(evaluator, species, results, state)
    raw_matrix = get_raw_matrix(evaluator, species, results)
    filtered_matrix = get_filtered_matrix(raw_matrix, evaluator)
    derived_matrix, all_cluster_ids = get_derived_matrix(evaluator, raw_matrix, filtered_matrix)
    println("ALL_CLUSTER_IDS = ", all_cluster_ids)
    reconstructed_filtered_matrix = reconstruct_matrix(raw_matrix, filtered_matrix)
    reconstructed_derived_matrix = reconstruct_matrix(raw_matrix, derived_matrix)
    records = create_records(
        evaluator, species, raw_matrix, reconstructed_filtered_matrix, reconstructed_derived_matrix
    )
    if evaluator.selection_method == "cluster_leader"
        new_parent_ids = get_cluster_leader_ids(species, all_cluster_ids, records)
    elseif evaluator.selection_method == "hillclimber"
        new_parent_ids = get_hillclimber_parent_ids(species, derived_matrix)
    elseif evaluator.selection_method == "truncation"
        n_population = length(species.population)
        new_parent_ids = [record.id for record in records[1:n_population]]
    else
        error("Selection method $(evaluator.selection_method) not recognized")
    end

    evaluation = TinEvaluation(
        id = evaluator.id, 
        new_parent_ids = new_parent_ids,
        raw_matrix = raw_matrix,
        filtered_matrix = reconstructed_filtered_matrix,
        matrix = reconstructed_derived_matrix,
        records = records
    )
    print_info(evaluator, raw_matrix, filtered_matrix, derived_matrix, records, all_cluster_ids)
    return evaluation
end

function create_test_matrix(
    test::Individual, learners::Vector{<:Individual}, test_results::Vector{<:Result}
)
    n_subtests = length(first(test_results).outcome_set[1])
    test_matrix = OutcomeMatrix(
        id = test.id, 
        row_ids = [learner.id for learner in learners], 
        column_ids = collect(1:n_subtests), 
        zeros(Float64, length(learners), n_subtests) 
    )
    for result in test_results
        learner_id = result.match.individual_ids[1]
        test_matrix[learner_id, :] = first(result.outcome_set)
    end
    return test_matrix
end

function fill_payoff_matrix_column!(
    evaluator::TinEvaluator,
    payoff_matrix::OutcomeMatrix, 
    test::Individual, 
    learner_species::AbstractSpecies, 
    results::Vector{<:Result}
)
    test_results = [result for result in results if test.id in result.match.individual_ids]
    test_matrix = create_test_matrix(test, learner_species, test_results)
    learner_records = create_records(evaluator, learner_species, test_matrix)
    maximum_rank = maximum(record.rank for record in learner_records)
    for learner_record in learner_records
        rank_score = maximum_rank - learner_record.rank
        payoff_matrix[learner_record.id, test.id] = rank_score
    end
end

function fill_payoff_matrix!(
    evaluator::TinEvaluator, 
    payoff_matrix::OutcomeMatrix, 
    learner_species::AbstractSpecies, 
    test_species::AbstractSpecies, 
    results::Vector{<:Result}
)
    for test in test_species
        fill_payoff_matrix_column!(evaluator, payoff_matrix, test, learner_species, results)
    end
end

function make_payoff_matrix(
    evaluator::TinEvaluator, 
    learner_species::AbstractSpecies, 
    test_species::AbstractSpecies,
    results::Vector{<:Result}
)
    payoff_matrix = OutcomeMatrix(
        id = "payoffs",
        row_ids = [learner.id for learner in learner_species],
        column_ids = [test.id for test in test_species],
        zeros(Float64, length(learner_species), length(test_species))
    )
    for test in test_species
        fill_payoff_matrix_column!(evaluator, payoff_matrix, test, learner_species, results)
    end
    return payoff_matrix
end

function evaluate(
    evaluator::TinEvaluator,
    ecosystem::Ecosystem,
    results::Vector{<:Result},
    state::State
)
    learner_species = ecosystem.all_species[1]
    test_species = ecosystem.all_species[2]
    payoff_matrix = make_payoff_matrix(evaluator, learner_species, test_species, results)
    learner_derived_matrix, learner_all_cluster_ids = get_derived_matrix(
        evaluator, payoff_matrix, payoff_matrix
    )
    learner_distinction_matrix = make_full_distinction_matrix(transpose(learner_derived_matrix))
    test_distinction_matrix = make_full_distinction_matrix(learner_derived_matrix)
    # make the distinction matrix for the tests
    # cluster over the columns to get the derived distinctions
    # cluster over the rows to get the test clusters
    # choose the cluster leaders for the tests based on their distance to centroid;
    # choose the hardest test of that group; if all equally hard, choose the one with
    # the better distinction score; if all equally hard and equally distinct, choose the youngest
    # if all the same age, choose randomly
    # choose the perimeter members of the cluster via farthest-first traversal 
    # starting from the cluster leader. 

    # for evaluation of the learners, assemble the records
    # sort first by pareto layer, then by distinction score, then by crowding, then by age
    # truncate by the top N learners
    # for the tests, collect the ids of the cluster leaders and the perimeter representatives


end