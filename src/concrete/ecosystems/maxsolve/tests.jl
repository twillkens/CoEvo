export update_tests_control!, update_tests_roulette!, update_tests_standard_distinctions!
export update_tests_advanced!, update_tests_p_phc!, update_tests_p_phc_p_frs!
export update_tests_p_phc_p_uhs!, add_winners!, get_active_retirees, update_tests_qmeu_slow!
export update_tests_qmeu_fast!

using ....Abstract
using StatsBase
using ....Interfaces
using ....Abstract
using ...Matrices.Outcome
using ...Matches.Basic
using Random
using ...Genotypes.FiniteStateMachines: create_random_fsm_genotype
using ...Genotypes.FiniteStateMachines
using ...Counters.Basic
using ...Phenotypes.Defaults


function update_tests_control!(
    reproducer::Reproducer, 
    ::SimpleEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_test_population = sample(
        state.rng, 
        [ecosystem.test_population ; ecosystem.test_children], 
        ecosystem_creator.n_test_population, 
        replace = false
    )
    parents = sample(
        state.rng, new_test_population, ecosystem_creator.n_test_children, replace = false
    )
    new_test_children = create_children(parents, reproducer, state)
    ecosystem.test_population = new_test_population
    ecosystem.test_children = new_test_children
end

function update_tests_roulette!(
    reproducer::Reproducer,
    evaluation::SimpleEvaluation,
    ecosystem::MaxSolveEcosystem,
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    fitness_matrix = make_sum_scalar_matrix(evaluation.payoff_matrix)
    new_test_population = select_individuals_aggregate(
        ecosystem, fitness_matrix, ecosystem_creator.n_test_population, state.rng
    )
    population_fitness_matrix = filter_rows(
        fitness_matrix, [test.id for test in new_test_population]
    )
    id_scores = [
        test => sum(population_fitness_matrix[test.id, :])
        for test in new_test_population
    ]
    #println("TESTS_id_scores = ", round.([id_score[2] for id_score in id_scores]; digits = 3))
    indices = roulette(
        state.rng, ecosystem_creator.n_test_children, 
        [id_score[2] + 0.00001 for id_score in id_scores]
    )
    test_parents = [first(id_score) for id_score in id_scores[indices]]
    new_test_children = create_children(test_parents, reproducer, state)
    ecosystem.test_population = new_test_population
    ecosystem.test_children = new_test_children
end

function update_tests_standard_distinctions!(
    reproducer::Reproducer, 
    evaluation::SimpleEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    distinction_matrix = make_full_distinction_matrix(evaluation.payoff_matrix)
    score_matrix = make_sum_scalar_matrix(distinction_matrix)
    new_test_population = select_individuals_aggregate(
        ecosystem, score_matrix, ecosystem_creator.n_test_population, state.rng
    )
    test_parents = sample(new_test_population, ecosystem_creator.n_test_children, replace = true)
    new_test_children = create_children(test_parents, reproducer, state)
    ecosystem.test_population = new_test_population
    ecosystem.test_children = new_test_children
end

function update_tests_advanced!(
    reproducer::Reproducer, 
    evaluation::SimpleEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    advanced_score_matrix = evaluate_advanced(evaluation.payoff_matrix, 3.0, 1.0)
    new_test_population = select_individuals_aggregate(
        ecosystem, advanced_score_matrix, ecosystem_creator.n_test_population, state.rng
    )
    test_parents = sample(new_test_population, ecosystem_creator.n_test_children, replace = true)
    new_test_children = create_children(test_parents, reproducer, state)
    ecosystem.test_population = new_test_population
    ecosystem.test_children = new_test_children
end

function update_tests_p_phc!(
    reproducer::Reproducer, 
    evaluation::SimpleEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ::MaxSolveEcosystemCreator,
    state::State
)
    new_population = copy(ecosystem.test_population)
    distinction_matrix = make_full_distinction_matrix(evaluation.payoff_matrix)
    for parent in ecosystem.test_population
        child = get_child(parent, ecosystem.test_children)
        n_parent_distinctions = sum(distinction_matrix[parent.id, :])
        n_child_distinctions = sum(distinction_matrix[child.id, :])
        if n_child_distinctions > n_parent_distinctions
            new_population = [indiv for indiv in new_population if indiv != parent]
            push!(new_population, child)
        end
    end
    new_children = create_children(new_population, reproducer, state)
    ecosystem.test_population = new_population
    ecosystem.test_children = new_children
end

function update_tests_p_phc_p_frs!(
    reproducer::Reproducer, 
    evaluation::SimpleEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_population = copy(ecosystem.test_population)
    for parent in ecosystem.test_population
        child = get_child(parent, ecosystem.test_children)
        parent_outcomes = evaluation.payoff_matrix[parent.id, :]
        child_outcomes = evaluation.payoff_matrix[child.id, :]
        parent_dominates_child = dominates(parent_outcomes, child_outcomes)
        if !parent_dominates_child
            new_population = [indiv for indiv in new_population if indiv != parent]
            push!(new_population, child)
        end
    end
    new_children = create_children(new_population, reproducer, state)
    ecosystem.test_population = new_population
    ecosystem.test_children = new_children
end

function update_tests_p_phc_p_uhs!(
    reproducer::Reproducer, 
    evaluation::SimpleEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_population = copy(ecosystem.test_population)
    for parent in ecosystem.test_population
        child = get_child(parent, ecosystem.test_children)
        parent_outcomes = evaluation.payoff_matrix[parent.id, :]
        child_outcomes = evaluation.payoff_matrix[child.id, :]
        parent_dominates_child = dominates(parent_outcomes, child_outcomes)
        child_at_same_or_higher_level = sum(child_outcomes) >= sum(parent_outcomes)
        if !parent_dominates_child && child_at_same_or_higher_level
            new_population = [indiv for indiv in new_population if indiv != parent]
            push!(new_population, child)
        end
    end
    new_children = create_children(new_population, reproducer, state)
    ecosystem.test_population = new_population
    ecosystem.test_children = new_children
end

function add_winners!(
    population::Vector{<:Individual}, 
    retirees::Vector{<:Individual},
    winners::Vector{<:Individual}, 
    max_archive_size::Int
)
    n_population = length(population)
    for winner in winners
        filter!(ind -> ind.id != winner.id, population)
        filter!(ind -> ind.id != winner.id, retirees)
        push!(population, winner)
        while length(population) > n_population
            retiree = popfirst!(population)
            filter!(ind -> ind.id != retiree.id, retirees)
            push!(retirees, retiree)
            if length(retirees) > max_archive_size
                popfirst!(retirees)
            end
        end
    end
end

function get_active_retirees(
    retirees::Vector{<:Individual}, 
    population::Vector{<:Individual}, 
    max_active_retirees::Int
)
    retiree_candidates = [retiree for retiree in retirees if !(retiree in population)]
    n_active_retirees = min(max_active_retirees, length(retiree_candidates))
    active_retirees = sample(retiree_candidates, n_active_retirees, replace = false)
    return active_retirees
end

function update_tests_qmeu_slow!(
    reproducer::Reproducer, 
    evaluation::SimpleEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_test_population = copy(ecosystem.test_population)
    new_test_retirees = copy(ecosystem.test_retirees)
    N_WINNERS = 1
    MAX_ACTIVE_RETIREES = 50
    MAX_ARCHIVE_SIZE = 1000
    distinction_matrix = make_full_distinction_matrix(evaluation.payoff_matrix)
    cfs_distinction_matrix = perform_competitive_fitness_sharing(distinction_matrix)
    sum_cfs_distinction_matrix = make_sum_scalar_matrix(cfs_distinction_matrix)
    winners = select_individuals_aggregate(
        ecosystem, sum_cfs_distinction_matrix, N_WINNERS, state.rng
    )
    add_winners!(new_test_population, new_test_retirees, winners, MAX_ARCHIVE_SIZE)
    active_retirees = get_active_retirees(new_test_retirees, new_test_population, MAX_ACTIVE_RETIREES)

    n_parents = length(new_test_population) - length(active_retirees)
    parents = sample(new_test_population, n_parents, replace = false)
    new_test_children = create_children(parents, reproducer, state; use_crossover = false)
    println("len new_test_children = ", length(new_test_children))
    println("len new_test_population = ", length(new_test_population))
    println("len active_retirees = ", length(active_retirees))

    misc_tests = [active_retirees ; new_test_children]

    if length(new_test_population) != length(ecosystem.test_population)
        error("LENGTHS = ", length(new_test_population), " ", length(ecosystem.test_population))
    end
    ecosystem.test_population = new_test_population
    ecosystem.test_children = misc_tests
    ecosystem.test_retirees = new_test_retirees
end

function update_tests_qmeu_fast!(
    reproducer::Reproducer, 
    evaluation::SimpleEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_test_population = copy(ecosystem.test_population)
    new_test_retirees = copy(ecosystem.test_retirees)
    N_WINNERS = 2
    MAX_ACTIVE_RETIREES = 50
    MAX_ARCHIVE_SIZE = 1000
    distinction_matrix = make_full_distinction_matrix(evaluation.payoff_matrix)
    cfs_distinction_matrix = perform_competitive_fitness_sharing(distinction_matrix)
    sum_cfs_distinction_matrix = make_sum_scalar_matrix(cfs_distinction_matrix)
    winners = select_individuals_aggregate(
        ecosystem, sum_cfs_distinction_matrix, N_WINNERS, state.rng
    )
    add_winners!(new_test_population, new_test_retirees, winners, MAX_ARCHIVE_SIZE)
    active_retirees = get_active_retirees(new_test_retirees, new_test_population, MAX_ACTIVE_RETIREES)

    n_parents = length(new_test_population) - length(active_retirees)
    parents = sample(new_test_population, n_parents, replace = false)
    new_test_children = create_children(parents, reproducer, state; use_crossover = false)
    println("len new_test_children = ", length(new_test_children))
    println("len new_test_population = ", length(new_test_population))
    println("len active_retirees = ", length(active_retirees))

    misc_tests = [active_retirees ; new_test_children]

    if length(new_test_population) != length(ecosystem.test_population)
        error("LENGTHS = ", length(new_test_population), " ", length(ecosystem.test_population))
    end
    ecosystem.test_population = new_test_population
    ecosystem.test_children = misc_tests
    ecosystem.test_retirees = new_test_retirees
end
# 
# function update_tests_qmeu_alpha(
#     reproducer::Reproducer, 
#     evaluation::MaxSolveEvaluation,
#     ecosystem::MaxSolveEcosystem, 
#     ecosystem_creator::MaxSolveEcosystemCreator,
#     state::State
# )
#     new_test_population = copy(ecosystem.test_population)
#     payoff_matrix = evaluation.payoff_matrix
#     N_ELITES = 2
#     MAX_ACTIVE_RETIREES = 10
#     MAX_ARCHIVE_SIZE = 1000
#     advanced_score_matrix = evaluate_advanced(payoff_matrix, 0.0, 1.0)
#     elites = select_individuals_aggregate(ecosystem, advanced_score_matrix, N_ELITES, state.rng)
#     for elite in elites
#         filter!(ind -> ind.id != elite.id, new_test_population)
#         filter!(ind -> ind.id != elite.id, ecosystem.retired_tests)
#         push!(new_test_population, elite)
#         while length(new_test_population) > ecosystem_creator.n_test_population
#             retiree = popfirst!(new_test_population)
#             filter!(ind -> ind.id != retiree.id, ecosystem.retired_tests)
#             push!(ecosystem.retired_tests, retiree)
#             if length(ecosystem.retired_tests) > MAX_ARCHIVE_SIZE
#                 popfirst!(ecosystem.retired_tests)
#             end
#         end
#     end
#     retiree_candidates = [retiree for retiree in ecosystem.retired_tests if !(retiree in new_test_population)]
#     n_active_retirees = min(MAX_ACTIVE_RETIREES, length(retiree_candidates))
#     active_retirees = sample(retiree_candidates, n_active_retirees, replace = false)
# 
#     n_parents = length(new_test_population) - n_active_retirees
#     parents = sample(new_test_population, n_parents, replace = false)
#     new_test_children = create_children(parents, reproducer, state; use_crossover = false)
#     println("len new_test_children = ", length(new_test_children))
#     println("len new_test_population = ", length(new_test_population))
#     println("len active_retirees = ", length(active_retirees))
# 
#     misc_tests = [active_retirees ; new_test_children]
# 
#     if length(new_test_population) != length(ecosystem.test_population)
#         error("LENGTHS = ", length(new_test_population), " ", length(ecosystem.test_population))
#     end
#     return new_test_population, misc_tests
# end
# 
# 
# 
# 
# function update_tests_qmeu_beta(
#     reproducer::Reproducer, 
#     evaluation::MaxSolveEvaluation,
#     ecosystem::MaxSolveEcosystem, 
#     ecosystem_creator::MaxSolveEcosystemCreator,
#     state::State
# )
#     new_test_population = copy(ecosystem.test_population)
#     payoff_matrix = evaluation.payoff_matrix
#     N_ELITES = 1
#     MAX_ACTIVE_RETIREES = 80
#     MAX_ARCHIVE_SIZE = 1000
#     advanced_score_matrix = evaluate_advanced(payoff_matrix, 0.0, 1.0)
#     elites = select_individuals_aggregate(ecosystem, advanced_score_matrix, N_ELITES, state.rng)
#     for elite in elites
#         filter!(ind -> ind.id != elite.id, new_test_population)
#         filter!(ind -> ind.id != elite.id, ecosystem.retired_tests)
#         push!(new_test_population, elite)
#         while length(new_test_population) > ecosystem_creator.n_test_population
#             retiree = popfirst!(new_test_population)
#             filter!(ind -> ind.id != retiree.id, ecosystem.retired_tests)
#             push!(ecosystem.retired_tests, retiree)
#             if length(ecosystem.retired_tests) > MAX_ARCHIVE_SIZE
#                 popfirst!(ecosystem.retired_tests)
#             end
#         end
#     end
#     retiree_candidates = [retiree for retiree in ecosystem.retired_tests if !(retiree in new_test_population)]
#     n_active_retirees = min(MAX_ACTIVE_RETIREES, length(retiree_candidates))
#     active_retirees = sample(retiree_candidates, n_active_retirees, replace = false)
# 
#     n_parents = length(new_test_population) - n_active_retirees
#     parents = sample(new_test_population, n_parents, replace = false)
#     new_test_children = create_children(parents, reproducer, state; use_crossover = false)
#     println("len new_test_children = ", length(new_test_children))
#     println("len new_test_population = ", length(new_test_population))
#     println("len active_retirees = ", length(active_retirees))
# 
#     misc_tests = [active_retirees ; new_test_children]
# 
#     if length(new_test_population) != length(ecosystem.test_population)
#         error("LENGTHS = ", length(new_test_population), " ", length(ecosystem.test_population))
#     end
#     return new_test_population, misc_tests
# end
# 
# 
# function update_tests_qmeu_gamma(
#     reproducer::Reproducer, 
#     evaluation::MaxSolveEvaluation,
#     ecosystem::MaxSolveEcosystem, 
#     ecosystem_creator::MaxSolveEcosystemCreator,
#     state::State
# )
#     new_test_population = copy(ecosystem.test_population)
#     payoff_matrix = evaluation.payoff_matrix
#     N_ELITES = 1
#     MAX_ACTIVE_RETIREES = 80
#     MAX_ARCHIVE_SIZE = 1000
#     advanced_score_matrix = evaluate_advanced(payoff_matrix, 0.0, 1.0)
#     elites = select_individuals_aggregate(ecosystem, advanced_score_matrix, N_ELITES, state.rng)
#     for elite in elites
#         filter!(ind -> ind.id != elite.id, new_test_population)
#         filter!(ind -> ind.id != elite.id, ecosystem.retired_tests)
#         push!(new_test_population, elite)
#         while length(new_test_population) > ecosystem_creator.n_test_population
#             retiree = popfirst!(new_test_population)
#             filter!(ind -> ind.id != retiree.id, ecosystem.retired_tests)
#             push!(ecosystem.retired_tests, retiree)
#             if length(ecosystem.retired_tests) > MAX_ARCHIVE_SIZE
#                 popfirst!(ecosystem.retired_tests)
#             end
#         end
#     end
#     retiree_candidates = [retiree for retiree in ecosystem.retired_tests if !(retiree in new_test_population)]
#     n_active_retirees = min(MAX_ACTIVE_RETIREES, length(retiree_candidates))
#     active_retirees = sample(retiree_candidates, n_active_retirees, replace = false)
# 
#     n_parents = length(new_test_population) - n_active_retirees
#     parents = sample(new_test_population, n_parents, replace = false)
#     new_test_children = create_children(parents, reproducer, state; use_crossover = false)
#     shuffle!(state.rng, new_test_children)
#     for i in 1:10
#         child_to_mutate = new_test_children[i]
#         n_states = length(child_to_mutate.genotype)
#         new_genotype = create_random_fsm_genotype(n_states, state.gene_id_counter, state.rng)
#         child_to_mutate.genotype = new_genotype
#         child_to_mutate.phenotype = create_phenotype(DefaultPhenotypeCreator(), child_to_mutate.id, child_to_mutate.genotype)
#     end
#     println("len new_test_children = ", length(new_test_children))
#     println("len new_test_population = ", length(new_test_population))
#     println("len active_retirees = ", length(active_retirees))
# 
#     misc_tests = [active_retirees ; new_test_children]
# 
#     if length(new_test_population) != length(ecosystem.test_population)
#         error("LENGTHS = ", length(new_test_population), " ", length(ecosystem.test_population))
#     end
#     return new_test_population, misc_tests
# end
# 
# function update_tests_dodo(
#     reproducer::Reproducer, 
#     evaluation::MaxSolveEvaluation,
#     ecosystem::MaxSolveEcosystem, 
#     ecosystem_creator::MaxSolveEcosystemCreator,
#     state::State
# )
#     new_test_population = copy(ecosystem.test_population)
#     new_parent_ids = [
#         evaluation.distinction_dodo_evaluation.cluster_leader_ids ; 
#         evaluation.distinction_dodo_evaluation.farthest_first_ids
#     ]
#     new_pop = [ecosystem[id] for id in new_parent_ids]
#     filter!(ind -> !(ind.id in new_parent_ids), new_test_population)
#     append!(new_test_population, new_pop)
#     n_new_retirees = 0
#     while length(new_test_population) > ecosystem_creator.n_test_population
#         n_new_retirees += 1
#         retiree = popfirst!(new_test_population)
#         #push!(ecosystem.retired_tests, retiree)
#         #if length(ecosystem.retired_tests) > 1000
#         #    popfirst!(ecosystem.retired_tests)
#         #end
#     end
#     #println("N_NEW_RETIREES = ", n_new_retirees)
#     #push!(new_learner_population, first(ecosystem.learner_children))
#     n_archive_parents = min(length(ecosystem.retired_tests), 20)
#     archive_parents = sample(ecosystem.retired_tests, n_archive_parents, replace = true)
#     random_parents = [deepcopy(parent) for parent in sample(new_test_population, 10, replace = true)]
#     for parent in random_parents
#         for i in eachindex(parent.genotype.genes)
#             parent.genotype.genes[i] = rand(0:1)
#         end
#     end
#     parents = [new_test_population ; archive_parents ; random_parents]
#     children = create_children(parents, reproducer, state; use_crossover = false)
#     #for _ in 1:length(children)
#     #    popfirst!(new_test_population)
#     #end
#     return new_test_population, children
# end
# 
# 
# 
# 
# 
# 
# 
#     ##n_random_immigrants = div(ecosystem_creator.n_learner_children, 4)
#     #n_random_immigrants = 25
#     #random_immigrants = create_children(
#     #    sample(new_test_population, n_random_immigrants, replace = true), reproducer, state; use_crossover = false
#     #)
#     #for immigrant in random_immigrants
#     #    for i in eachindex(immigrant.genotype.genes)
#     #        immigrant.genotype.genes[i] = rand(0:1)
#     #    end
#     #end
#     #println("len random immigrants = ", length(random_immigrants))
#     #misc_tests = [active_retirees ; random_immigrants; new_test_children]
# 
#     #for _ in 1:5
#     #    competitors = sample(new_test_population, 3, replace = false)
#     #    id_scores = [
#     #        learner => sum(evaluation.learner_score_matrix[learner.id, :]) 
#     #        for learner in competitors
#     #    ]
#     #    parent = first(reduce(
#     #        (id_score_1, id_score_2) -> id_score_1[2] > id_score_2[2] ? 
#     #        id_score_1 : id_score_2, 
#     #        shuffle(id_scores)
#     #    ))
#     #    push!(parents, parent)
#     #end
#     #new_learner_children = create_children(parents, reproducer, state)
#     #for _ in 1:5
#     #    popfirst!(new_learner_population)
#     #end
# 
# OLD
#function update_tests_roulette(
#    reproducer::Reproducer,
#    evaluation::MaxSolveEvaluation,
#    ecosystem::MaxSolveEcosystem,
#    ecosystem_creator::MaxSolveEcosystemCreator,
#    state::State
#)
#    #new_learner_population = select_individuals_aggregate(
#    #    ecosystem, evaluation.advanced_score_matrix, ecosystem_creator.n_learner_population
#    #)
#    new_test_population = [ecosystem.test_population ; ecosystem.test_children]
#    n_sample_population = ecosystem_creator.n_test_population + ecosystem_creator.n_test_children
#    id_scores = [
#        test => sum(evaluation.payoff_matrix[test.id, :])
#        for test in new_test_population
#    ]
#    println("TEST_id_scores = ", round.([id_score[2] for id_score in id_scores]; digits = 3))
#    indices = roulette(state.rng, n_sample_population, [id_score[2] + 0.00001 for id_score in id_scores] )
#    println("indices = ", indices)
#    test_parents = [first(id_score) for id_score in id_scores[indices]]
#    new_test_children = create_children(test_parents, reproducer, state)
#    new_test_population, new_test_children = new_test_children[1:100],  new_test_children[101:200]
#    return new_test_population, new_test_children
#end