export MaxSolveEcosystem, MaxSolveEcosystemCreator, MaxSolveEvaluation
export MaxSolveSpeciesParameters, MaxSolveEcosystemCreator, NewDodoRecord, NewDodoEvaluation
export create_ecosystem, update_ecosystem!, evaluate, make_all_matches
export get_all_individuals
export create_children

import ....Interfaces: make_all_matches, update_species!
using Random
using StatsBase
using ...Ecosystems.Simple: SimpleEcosystem
using ...Species.Basic: BasicSpecies
using ...Recombiners.Clone: CloneRecombiner
using ....Interfaces
using ....Abstract
using ...Matrices.Outcome
using ...Matches.Basic


function create_children(
    n_children::Int, parents::Vector{<:Individual}, reproducer::Reproducer, state::State
)
    children = recombine(
        reproducer.recombiner, reproducer.mutator, reproducer.phenotype_creator, parents, state
    )
    if length(children) != n_children
        error("length(children) = $(length(children)), expected $n_children")
    end
    return children
end

function initialize_population_and_children(
    reproducer::Reproducer, params::MaxSolveSpeciesParameters, state::State
)
    population = create_individuals(
        reproducer.individual_creator, params.n_population, reproducer, state
    )
    parents = sample(population, params.n_parents, replace = true)
    children = create_children(params.n_children, parents, reproducer, state)
    return population, children
end


function create_ecosystem(
    eco_creator::MaxSolveEcosystemCreator, reproducers::Vector{<:Reproducer}, state::State
)
    if length(reproducers) != 2
        error("length(reproducers) = $(length(reproducers)), expected 2")
    end
    learner_population, learner_children = initialize_population_and_children(
        first(reproducers), eco_creator.learners, state
    )
    test_population, test_children = initialize_population_and_children(
        last(reproducers), eco_creator.tests, state
    )

    I = typeof(first(learner_population))
    active_learners = [learner_population ; learner_children]
    learners = MaxSolveSpecies("L", learner_population, learner_children, I[], I[], active_learners)
    active_tests = [test_population ; test_children]
    tests = MaxSolveSpecies("T", test_population, test_children, I[], I[], active_tests)
    new_ecosystem = MaxSolveEcosystem(id = eco_creator.id, learners = learners, tests = tests)
    return new_ecosystem
end


function print_pop_lengths(ecosystem::MaxSolveEcosystem)
    println(
        "LEARNERS LENGTH: population = ", length(ecosystem.learners.population), 
        ", children = ", length(ecosystem.learners.children), 
        ", archive = ", length(ecosystem.learners.archive), 
        ", retirees = ", length(ecosystem.learners.retirees),
        ", active = ", length(ecosystem.learners.active)
    )
    println(
        "TESTS LENGTH: population = ", length(ecosystem.tests.population), 
        ", children = ", length(ecosystem.tests.children), 
        ", archive = ", length(ecosystem.tests.archive), 
        ", retirees = ", length(ecosystem.tests.retirees),
        ", active = ", length(ecosystem.tests.active)
    )
end

function get_ids_truncation_replacement(
    score_matrix::OutcomeMatrix, n::Int, rng::AbstractRNG = Random.GLOBAL_RNG
)
    if length(score_matrix.column_ids) > 1
        error("Truncation selection only works with a single column for scalar fitness")
    end
    id_scores = shuffle(rng, [id => first(score_matrix[id, :]) for id in score_matrix.row_ids])
    println("ID_SCORES = ", id_scores)
    sort!(id_scores, by=x-> (x[2], rand(rng)), rev=true)
    println("SORTED_ID_SCORES = ", id_scores)
    ids = [first(id_score) for id_score in id_scores[1:n]]
    return ids
end

function make_standard_sum_matrix(matrix::OutcomeMatrix)
    average_scalar_matrix = OutcomeMatrix{Float64}(matrix.id, matrix.row_ids, ["sum"])
    for i in matrix.row_ids
        average_scalar_matrix[i, "sum"] = sum(matrix[i, :])
    end
    return average_scalar_matrix
end

function perform_competitive_sharing(matrix::OutcomeMatrix)
    # Calculate the sum of each column and then take the inverse
    test_defeats_inverses = 1.0 ./ sum(matrix.data, dims=1)

    # Create a new OutcomeMatrix with the same dimensions
    new_matrix = OutcomeMatrix{Float64}(matrix.id, matrix.row_ids, matrix.column_ids)

    # Use broadcasting to divide each column element by the corresponding test defeat sum
    new_matrix.data = matrix.data .* test_defeats_inverses

    return new_matrix
end

function make_competitive_sum_matrix(matrix::OutcomeMatrix)
    competitive_matrix = perform_competitive_sharing(matrix)
    sum_matrix = make_standard_sum_matrix(competitive_matrix)
    return sum_matrix
end


function zero_out_duplicate_rows(
    matrix::OutcomeMatrix{T, U, V, W}, rng::AbstractRNG = Random.GLOBAL_RNG
) where {T, U, V, W}
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
    ids_to_keep = Set(rand(rng, ids) for ids in values(unique_rows))
    #println("IDs to keep = ", ids_to_keep)
    for id in matrix.row_ids
        if !(id in ids_to_keep)
            for column_id in matrix.column_ids
                matrix[id, column_id] = W(0)
            end
        end
    end
    return matrix
end

function get_score_matrix(
    matrix::OutcomeMatrix, 
    zero_dup_rows::Bool, 
    competitive_sharing::Bool, 
    weight::Float64,
    rng::AbstractRNG = Random.GLOBAL_RNG
)
    matrix = zero_dup_rows ? zero_out_duplicate_rows(matrix, rng) : matrix
    matrix = competitive_sharing ? 
        make_competitive_sum_matrix(matrix) : make_standard_sum_matrix(matrix)
    matrix.data = matrix.data .* weight
    return matrix
end

function get_score_matrix(matrix::OutcomeMatrix, params::ScoreParameters, rng::AbstractRNG)
    matrix = get_score_matrix(
        matrix, params.zero_out_duplicate_rows, params.competitive_sharing, params.weight, rng
    )
    return matrix
end

function add_matrices(matrix1::OutcomeMatrix, matrix2::OutcomeMatrix)
    total_scores = deepcopy(matrix1)
    total_scores.column_ids[1] = "total"
    distinction_col_id = first(matrix2.column_ids)
    for row_id in total_scores.row_ids
        total_scores[row_id, "total"] += matrix2[row_id, distinction_col_id]
    end
    return total_scores
end

function run_tournament(contenders::Array{<:DiscoRecord}, rng::AbstractRNG) 
    function get_winner(record_1::DiscoRecord, record_2::DiscoRecord)
        if record_1.rank < record_2.rank
            return record_1
        elseif record_2.rank < record_1.rank
            return record_2
        else
            if record_1.crowding > record_2.crowding
                return record_1
            elseif record_2.crowding > record_1.crowding
                return record_2
            else
                return rand(rng, (record_1, record_2))
            end
        end
    end
    winner = reduce(get_winner, contenders)
    return winner
end

function update_species!(
    species::MaxSolveSpecies,
    species_params::MaxSolveSpeciesParameters,
    update_params::DiscoParameters,
    evaluation::MaxSolveEvaluation,
    reproducer::Reproducer, 
    state::State
)
    println("------DISCO $(species.id)------")
    disco_evaluation = evaluate_disco(evaluation.payoff_matrix, species.id, state)
    records = disco_evaluation.records[1:species_params.n_population]
    new_population = [species[record.id] for record in records]

    tournament_samples = [
        sample(records, 5, replace = false) for _ in 1:species_params.n_children
    ]
    selected_records = [
        run_tournament(samples, state.rng) for samples in tournament_samples
    ]
    println("SELECTED_LEARNER_RECORDS = ", [
        (record.rank, round(record.crowding; digits=3)) 
        for record in selected_records]
    )   
    learner_parents = [species[record.id] for record in selected_records]
    new_learner_children = create_children(
        species_params.n_children, learner_parents, reproducer, state
    )
    species.population = new_population
    species.children = new_learner_children
    species.active = [new_population ; new_learner_children]
end

function print_scores(matrix::OutcomeMatrix, tag::String)
    scores = sort(round.([first(matrix[id, :]) for id in matrix.row_ids]; digits=2); rev = true)
    println("$(tag)_SCORES = ", scores)
end

function update_species!(
    species::MaxSolveSpecies,
    species_params::MaxSolveSpeciesParameters,
    update_params::EvolutionStrategyParameters,
    evaluation::MaxSolveEvaluation,
    reproducer::Reproducer, 
    state::State
)
    println("------EVOLUTION STRATEGY UPDATE: $(species.id)------")
    n_parents, n_children = species_params.n_parents, species_params.n_children
    population, children = species.population, species.children
    raw_outcome_matrix = get_score_matrix(
        evaluation.payoff_matrix, ScoreParameters(false, false, 1.0), state.rng
    )
    print_scores(raw_outcome_matrix, "RAW")
    outcome_scores = get_score_matrix(
        evaluation.payoff_matrix, update_params.outcomes, state.rng
    )
    distinction_scores = get_score_matrix(
        evaluation.distinction_matrix, update_params.distinctions, state.rng
    )
    total_matrix = add_matrices(outcome_scores, distinction_scores)
    print_scores(total_matrix, "TOTAL")
    candidates = [population ; children]
    candidate_ids = [candidate.id for candidate in candidates]
    if Set(candidate_ids) != Set(total_matrix.row_ids)
        error("candidate_ids = $candidate_ids, matrix.row_ids = $(total_matrix.row_ids)")
    end
    population_ids = get_ids_truncation_replacement(total_matrix, length(population), state.rng)
    new_population = [candidate for candidate in candidates if candidate.id in population_ids]
    parents = sample(state.rng, new_population, n_parents, replace = true)
    new_children = create_children(n_children, parents, reproducer, state)
    species.population = new_population
    species.children = new_children
    species.active = [new_population ; new_children]
end

function add_elites!(
    species::MaxSolveSpecies, 
    ::DodoParameters, 
    species_params::MaxSolveSpeciesParameters, 
    elites::Vector{<:Individual}
)
    for elite in elites
        filter!(ind -> ind.id != elite.id, species.population)
        filter!(ind -> ind.id != elite.id, species.retirees)
        println("len pop after filter = ", length(species.population))
        push!(species.population, elite)
        println("len pop after push = ", length(species.population))
        while length(species.population) > species_params.n_population
            retiree = popfirst!(species.population)
            println("length of pop after pop = ", length(species.population))
            filter!(ind -> ind.id != retiree.id, species.retirees)
            println("length of retirees after filter = ", length(species.retirees))
            push!(species.retirees, retiree)
            println("length of retirees after push = ", length(species.retirees))
            if length(species.retirees) > species_params.max_retiree_size
                popfirst!(species.retirees)
                println("length of retirees after popfirst = ", length(species.retirees))
            end
        end
    end
end

function get_active_retirees(species::MaxSolveSpecies, params::MaxSolveSpeciesParameters)
    retiree_candidates = [retiree for retiree in species.retirees if !(retiree in species.population)]
    n_active_retirees = min(length(retiree_candidates), params.max_active_retirees)
    active_retirees = sample(retiree_candidates, n_active_retirees, replace = false)
    return active_retirees
end

function update_species!(
    species::MaxSolveSpecies,
    species_params::MaxSolveSpeciesParameters,
    update_params::DodoParameters,
    evaluation::MaxSolveEvaluation,
    reproducer::Reproducer, 
    state::State
)
    println("------DODO UPDATE: $(species.id)------")
    raw_outcome_matrix = get_score_matrix(
        evaluation.payoff_matrix, ScoreParameters(false, false, 1.0), state.rng
    )
    print_scores(raw_outcome_matrix, "RAW")
    
    # Generate score matrices based on DodoParameters
    outcome_scores = get_score_matrix(evaluation.payoff_matrix, update_params.outcomes, state.rng)
    distinction_scores = get_score_matrix(
        evaluation.distinction_matrix, update_params.distinctions, state.rng
    )
    
    # Combine scores for total evaluation
    total_matrix = add_matrices(outcome_scores, distinction_scores)
    print_scores(total_matrix, "TOTAL")
    
    # Select elites based on the total scores
    n_elites = min(species_params.n_population, update_params.n_elites)  # Adjust number of elites if necessary
    elite_ids = get_ids_truncation_replacement(total_matrix, n_elites, state.rng)
    elites = [species[individual_id] for individual_id in elite_ids]
    add_elites!(species, update_params, species_params, elites)
    active_retirees = get_active_retirees(species, species_params)
    n_parents = species_params.n_parents - length(active_retirees)
    n_children = species_params.n_children - length(active_retirees)

    # Maintain population size with new children
    parents = sample(state.rng, species.population, n_parents, replace = true)
    new_children = create_children(n_children, parents, reproducer, state)
    # Update species
    species.children = new_children
    species.active = [species.population; new_children ; active_retirees]  # Update active list if necessary
end

function update_ecosystem!(
    parameters::EcosystemScoreParameters, 
    ecosystem::MaxSolveEcosystem,
    ecosystem_creator::MaxSolveEcosystemCreator,
    learner_evaluation::MaxSolveEvaluation,
    test_evaluation::MaxSolveEvaluation,
    state::State
)
    update_species!(
        ecosystem.learners, ecosystem_creator.learners, parameters.learners, learner_evaluation, 
        first(state.reproducers), state
    )
    update_species!(
        ecosystem.tests, ecosystem_creator.tests, parameters.tests, test_evaluation, 
        last(state.reproducers), state
    )
end

function update_ecosystem!(
    ecosystem::MaxSolveEcosystem, ecosystem_creator::MaxSolveEcosystemCreator, state::State
)
    println("------UPDATE ECOSYSTEM: GENERATION: $(state.generation) ------")
    algorithm = ecosystem_creator.algorithm
    learner_evaluation = first(state.evaluations)
    test_evaluation = last(state.evaluations)
    parameters = SCORE_PARAMS[algorithm]
    update_ecosystem!(
        parameters, ecosystem, ecosystem_creator, learner_evaluation, test_evaluation, state
    )
    print_pop_lengths(ecosystem)
end

function create_outcome_matrix(species_id::String, outcomes::Vector{<:Result})
    filtered_outcomes = filter(x -> x.species_id == species_id, outcomes)
    ids = sort(unique([outcome.id for outcome in filtered_outcomes]))
    other_ids = sort(unique([outcome.other_id for outcome in filtered_outcomes]))
    #W = typeof(first(outcomes).outcome)
    if length(filtered_outcomes) != length(ids) * length(other_ids)
        error("length(filtered_outcomes) = $(length(filtered_outcomes)), length(ids) = $(length(ids)), length(other_ids) = $(length(other_ids))")
    end
    outcome_matrix = OutcomeMatrix{Bool}(species_id, ids, other_ids)
    for outcome in filtered_outcomes
        outcome_matrix[outcome.id, outcome.other_id] = Bool(outcome.outcome)
    end
    return outcome_matrix
end

function MaxSolveEvaluation(species_id::String, outcomes::Vector{<:Result})
    outcome_matrix = create_outcome_matrix(species_id, outcomes)
    distinction_matrix = make_full_distinction_matrix(outcome_matrix)
    evaluation = MaxSolveEvaluation(
        species_id, 
        outcome_matrix, 
        distinction_matrix, 
    )
    return evaluation

end

function evaluate(::MaxSolveEcosystem, ::Vector{<:Evaluator}, results::Vector{<:Result}, ::State)
    outcomes = vcat([get_individual_outcomes(result) for result in results]...)
    learner_evaluation = MaxSolveEvaluation("L", outcomes)
    test_evaluation = MaxSolveEvaluation("T", outcomes)
    return [learner_evaluation, test_evaluation]
end

#Base.getindex(ecosystem::MaxSolveEcosystem, species_id::String) = begin
#    if species_id == "L"
#        return ecosystem.learner_population
#    elseif species_id == "T"
#        return ecosystem.test_population
#    elseif species_id == "LA"
#        return ecosystem.learner_archive
#    elseif species_id == "TA"
#        return ecosystem.test_archive
#    else
#        error("species_id = $species_id not found in ecosystem")
#    end
#end

# function update_maxsolve_archive!(
#     ecosystem_creator::MaxSolveEcosystemCreator, 
#     ecosystem::MaxSolveEcosystem, 
#     payoff_matrix::OutcomeMatrix
# )
#     if ecosystem_creator.maxsolve_archive_size > 0
#         maxsolve_matrix = maxsolve(payoff_matrix, ecosystem_creator.maxsolve_archive_size)
#         new_learner_archive = [ecosystem[learner_id] for learner_id in maxsolve_matrix.row_ids]
#         retired_learners = [
#             learner for learner in ecosystem.learner_archive if learner.id ∉ maxsolve_matrix.row_ids
#         ]
#         append!(ecosystem.learner_retirees, retired_learners)
#         while length(ecosystem.learner_retirees) > 1000
#             popfirst!(ecosystem.learner_retirees)
#         end
# 
#         new_test_archive = [ecosystem[test_id] for test_id in maxsolve_matrix.column_ids]
#         test_retirees = [
#             test for test in ecosystem.test_archive if test.id ∉ maxsolve_matrix.column_ids
#         ]
#         append!(ecosystem.test_retirees, test_retirees)
#         while length(ecosystem.test_retirees) > 1000
#             popfirst!(ecosystem.test_retirees)
#         end
# 
#         ecosystem.learner_archive = new_learner_archive
#         ecosystem.test_archive = new_test_archive
#     end
# end