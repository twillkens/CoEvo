using ....Abstract
using StatsBase
import ....Interfaces: make_all_matches
using ....Interfaces
using ....Abstract
using ...Matrices.Outcome
using ...Matches.Basic
using Random


function update_tests_standard_distinctions(
    reproducer::Reproducer, 
    evaluation::QueMEUEvaluation,
    ecosystem::QueMEUEcosystem, 
    ecosystem_creator::QueMEUEcosystemCreator,
    state::State
)
    matrix = make_sum_scalar_matrix(evaluation.distinction_matrix)
    new_test_population = select_individuals_aggregate(
        ecosystem, matrix, ecosystem_creator.n_test_population
    )
    test_parents = sample(new_test_population, ecosystem_creator.n_test_children, replace = true)
    new_test_children = create_children(test_parents, reproducer, state)
    return new_test_population, new_test_children
end

function update_tests_advanced(
    reproducer::Reproducer, 
    evaluation::QueMEUEvaluation,
    ecosystem::QueMEUEcosystem, 
    ecosystem_creator::QueMEUEcosystemCreator,
    state::State
)
    new_test_population = select_individuals_aggregate(
        ecosystem, evaluation.advanced_score_matrix, ecosystem_creator.n_test_population
    )
    test_parents = sample(new_test_population, ecosystem_creator.n_test_children, replace = true)
    new_test_children = create_children(test_parents, reproducer, state)
    return new_test_population, new_test_children
end

function update_tests_quemeu(
    reproducer::Reproducer, 
    evaluation::QueMEUEvaluation,
    ecosystem::QueMEUEcosystem, 
    ecosystem_creator::QueMEUEcosystemCreator,
    state::State
)
    new_test_population = copy(ecosystem.test_population)
    payoff_matrix = evaluation.payoff_matrix
    N_ELITES = 2
    MAX_ACTIVE_RETIREES = 10
    MAX_ARCHIVE_SIZE = 1000
    advanced_score_matrix = evaluate_advanced(payoff_matrix, 0.0, 1.0)
    elites = select_individuals_aggregate(ecosystem, advanced_score_matrix, N_ELITES)
    for elite in elites
        filter!(ind -> ind.id != elite.id, new_test_population)
        filter!(ind -> ind.id != elite.id, ecosystem.retired_tests)
        push!(new_test_population, elite)
        while length(new_test_population) > ecosystem_creator.n_test_population
            retiree = popfirst!(new_test_population)
            filter!(ind -> ind.id != retiree.id, ecosystem.retired_tests)
            push!(ecosystem.retired_tests, retiree)
            if length(ecosystem.retired_tests) > MAX_ARCHIVE_SIZE
                popfirst!(ecosystem.retired_tests)
            end
        end
    end
    retiree_candidates = [retiree for retiree in ecosystem.retired_tests if !(retiree in new_test_population)]
    n_active_retirees = min(MAX_ACTIVE_RETIREES, length(retiree_candidates))
    active_retirees = sample(retiree_candidates, n_active_retirees, replace = false)

    n_parents = length(new_test_population) - n_active_retirees
    parents = sample(new_test_population, n_parents, replace = false)
    new_test_children = create_children(parents, reproducer, state; use_crossover = false)
    println("len new_test_children = ", length(new_test_children))
    println("len new_test_population = ", length(new_test_population))
    println("len active_retirees = ", length(active_retirees))

    misc_tests = [active_retirees ; new_test_children]

    if length(new_test_population) != length(ecosystem.test_population)
        error("LENGTHS = ", length(new_test_population), " ", length(ecosystem.test_population))
    end
    return new_test_population, misc_tests
end

