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
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
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

function update_tests_dodo(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_test_population = copy(ecosystem.test_population)
    new_parent_ids = [
        evaluation.distinction_dodo_evaluation.cluster_leader_ids ; 
        evaluation.distinction_dodo_evaluation.farthest_first_ids
    ]
    new_pop = [ecosystem[id] for id in new_parent_ids]
    filter!(ind -> !(ind.id in new_parent_ids), new_test_population)
    append!(new_test_population, new_pop)
    n_new_retirees = 0
    while length(new_test_population) > ecosystem_creator.n_test_population
        n_new_retirees += 1
        retiree = popfirst!(new_test_population)
        #push!(ecosystem.retired_tests, retiree)
        #if length(ecosystem.retired_tests) > 1000
        #    popfirst!(ecosystem.retired_tests)
        #end
    end
    #println("N_NEW_RETIREES = ", n_new_retirees)
    #push!(new_learner_population, first(ecosystem.learner_children))
    n_archive_parents = min(length(ecosystem.retired_tests), 20)
    archive_parents = sample(ecosystem.retired_tests, n_archive_parents, replace = true)
    random_parents = [deepcopy(parent) for parent in sample(new_test_population, 10, replace = true)]
    for parent in random_parents
        for i in eachindex(parent.genotype.genes)
            parent.genotype.genes[i] = rand(0:1)
        end
    end
    parents = [new_test_population ; archive_parents ; random_parents]
    children = create_children(parents, reproducer, state; use_crossover = false)
    #for _ in 1:length(children)
    #    popfirst!(new_test_population)
    #end
    return new_test_population, children
end

function update_tests_farthest_first(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    #elites = select_individuals_aggregate(ecosystem, evaluation.advanced_score_matrix, 5)
    #elite_ids = [individual.id for individual in elites]
    #farthest_first_ordering = farthest_first_traversal(evaluation.distinction_matrix, elite_ids)
    #farthest_first_ordering = [elite_ids ; farthest_first_ordering]
    filtered_distinction_matrix = get_filtered_matrix(evaluation.distinction_matrix)
    score_matrix = evaluate_advanced(filtered_distinction_matrix)
    elites = select_individuals_aggregate(ecosystem, score_matrix, min(length(score_matrix.row_ids), 5))
    elite_ids = [individual.id for individual in elites]
    farthest_first_ordering = farthest_first_traversal(filtered_distinction_matrix, elite_ids)
    farthest_first_ordering = [elite_ids ; farthest_first_ordering]
    nonordered_ids = shuffle([
        id for id in evaluation.distinction_matrix.row_ids if !(id in farthest_first_ordering)
    ])
    append!(farthest_first_ordering, nonordered_ids)

    new_test_population = [
        ecosystem[id] for id in farthest_first_ordering][1:ecosystem_creator.n_test_population
    ]
    id_scores = [
        test => sum(evaluation.advanced_score_matrix[test.id, :]) for test in new_test_population
    ]
    println("id_scores = ", round.([id_score[2] for id_score in id_scores]; digits = 3))
    test_parents = sample(
        new_test_population,
        ecosystem_creator.n_test_children, replace = true
    )
    n_active_retirees = min(length(ecosystem.retired_tests), div(ecosystem_creator.n_learner_children, 4))
    active_retirees = sample(ecosystem.retired_tests, n_active_retirees, replace = false)
    random_parents = [
        deepcopy(parent) 
        for parent in sample(
            new_test_population, div(ecosystem_creator.n_learner_children, 4), replace = true
        )]
    for parent in random_parents
        for i in eachindex(parent.genotype.genes)
            parent.genotype.genes[i] = rand(0:1)
        end
    end
    append!(test_parents, random_parents)
    new_test_children = create_children(test_parents, reproducer, state; use_crossover = false)
    return active_retirees, new_test_children
end

function update_tests_nu_advanced(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_test_population = select_individuals_aggregate(
        ecosystem, evaluation.advanced_score_matrix, ecosystem_creator.n_test_population
    )
    n_sample_population = ecosystem_creator.n_test_children
    id_scores = [
        learner => sum(evaluation.advanced_score_matrix[learner.id, :]) 
        for learner in new_test_population
    ]
    println("id_scores = ", round.([id_score[2] for id_score in id_scores]; digits = 3))
    indices = roulette(state.rng, n_sample_population, [id_score[2] + 0.00001 for id_score in id_scores] )
    println("indices = ", indices)
    test_parents = [first(id_score) for id_score in id_scores[indices]]
    test_parents = sample(
        [new_test_population ; ecosystem.test_archive; ecosystem.retired_tests], 
        ecosystem_creator.n_test_children, replace = true
    )
    n_active_retirees = min(length(ecosystem.retired_tests), div(ecosystem_creator.n_learner_children, 4))
    active_retirees = sample(ecosystem.retired_tests, n_active_retirees, replace = false)
    random_parents = [deepcopy(parent) for parent in sample(new_test_population, 10, replace = true)]
    for parent in random_parents
        for i in eachindex(parent.genotype.genes)
            parent.genotype.genes[i] = rand(0:1)
        end
    end
    append!(test_parents, random_parents)
    new_test_children = create_children(test_parents, reproducer, state; use_crossover = false)
    return active_retirees, new_test_children
end

function update_tests_advanced(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_test_population = select_individuals_aggregate(
        ecosystem, evaluation.advanced_score_matrix, ecosystem_creator.n_test_population
    )
    test_parents = sample(
        [new_test_population ; ecosystem.test_archive], 
        ecosystem_creator.n_test_children, replace = true
    )
    #random_parents = [deepcopy(parent) for parent in sample(new_test_population, 10, replace = true)]
    #for parent in random_parents
    #    for i in eachindex(parent.genotype.genes)
    #        parent.genotype.genes[i] = rand(0:1)
    #    end
    #end
    #append!(test_parents, random_parents)
    #n_sample_archive = min(length(ecosystem.test_archive), 20)
    #archive_parents = sample(
    #    ecosystem.test_archive, n_sample_archive, replace = true
    #)
    #append!(test_parents, archive_parents)
    new_test_children = create_children(test_parents, reproducer, state)
    return new_test_population, new_test_children
end

function update_tests_no_elites(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_test_population = select_individuals_aggregate(
        ecosystem, evaluation.test_score_matrix, ecosystem_creator.n_test_population
    )
    println("length_test_population = ", length(new_test_population))
    I = typeof(first(new_test_population))

    #n_sample_archive = min(length(ecosystem.learner_archive), 10)
    n_sample_archive = min(length(ecosystem.test_archive), ecosystem_creator.n_test_population)
    if n_sample_archive == 0
        new_archive_children = I[]
    else
        archive_parents = sample(
            ecosystem.test_archive, n_sample_archive, replace = true
        )
        new_archive_children = create_children(archive_parents, reproducer, state)
    end
    n_sample_retirees = min(length(ecosystem.test_archive), 100)
    if n_sample_retirees > 0
        sampled_retirees = sample(
            ecosystem.test_archive, n_sample_retirees, replace = true
        )
        retiree_children = create_children(sampled_retirees, reproducer, state)
        append!(new_archive_children, retiree_children)
    end
    
    n_sample_population = ecosystem_creator.n_test_children + 
                          ecosystem_creator.n_test_population - n_sample_archive
    println("n_sample_archive = ", n_sample_archive)
    println("n_sample_population = ", n_sample_population)
    println("n_sample_retirees = ", n_sample_retirees)
    test_parents = sample(
        new_test_population, n_sample_population, replace = true
    )

    new_test_children = create_children(test_parents, reproducer, state)
    return I[], [new_archive_children ; new_test_children]
    #return new_learner_population, new_learner_children
end

function update_tests_regularized(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_test_population = copy(ecosystem.test_population)
    #payoff_matrix = filter_columns(
    #    evaluation.payoff_matrix, [learner.id for learner in ecosystem.learner_population]
    #)
    payoff_matrix = evaluation.payoff_matrix
    N_ELITES = 2
    MAX_ACTIVE_RETIREES = 25
    MAX_ARCHIVE_SIZE = 1000
    advanced_score_matrix = evaluate_advanced(payoff_matrix, 0.0, 1.0)
    elites = select_individuals_aggregate(ecosystem, advanced_score_matrix, N_ELITES)
    elite_ids = [elite.id for elite in elites]
    farthest_ids = farthest_first_traversal(evaluation.distinction_matrix, elite_ids)[1:1]
    println("farthest_ids = ", farthest_ids)
    farthest = [ind for ind in [ecosystem.test_population ; ecosystem.test_children] if ind.id in farthest_ids]
    append!(elites, farthest)
    #random_elites = select_individuals_aggregate(ecosystem, advanced_score_matrix, 50)
    #random_elites = shuffle([elite for elite in random_elites if !(elite in elites)])[1:N_ELITES]
    #append!(elites, random_elites)
    #if state.generation > 99 && state.generation % 10 == 0
    #        random_immigrants = create_children(
    #    	sample(new_test_population, 1, replace = true), reproducer, state; use_crossover = false
    #        )
    #        for immigrant in random_immigrants
    #    	for i in eachindex(immigrant.genotype.genes)
    #    	    immigrant.genotype.genes[i] = rand(0:1)
    #    	end
    #        end
    #        append!(elites, random_immigrants)
    #end
    #if length(ecosystem.retired_tests) > 0
    #        random_retiree = rand(ecosystem.retired_tests)
    #        #retiree_child = first(create_children([random_retiree], reproducer, state; use_crossover = false))
    #        push!(elites, random_retiree)
    #end
    #println("len elites = ", length(elites))
    for elite in elites
	#if elite in new_test_population
	#	child = first(create_children([elite], reproducer, state; use_crossover = false))
	#	push!(new_test_population, child)
	#end

        filter!(ind -> ind.id != elite.id, new_test_population)
        filter!(ind -> ind.id != elite.id, ecosystem.retired_tests)
        #println("len pop after filter = ", length(new_test_population))
        push!(new_test_population, elite)
        #println("len pop after push = ", length(new_test_population))
        while length(new_test_population) > ecosystem_creator.n_test_population
            retiree = popfirst!(new_test_population)
            #retiree_child = first(create_children([random_retiree], reproducer, state; use_crossover = false))
            filter!(ind -> ind.id != retiree.id, ecosystem.retired_tests)
            push!(ecosystem.retired_tests, retiree)
            if length(ecosystem.retired_tests) > MAX_ARCHIVE_SIZE
                popfirst!(ecosystem.retired_tests)
            end
        end
    end
    n_active_retirees = min(MAX_ACTIVE_RETIREES, length(ecosystem.retired_tests))
    n_parents = length(new_test_population) - n_active_retirees
    parents = sample(new_test_population, n_parents, replace = false)
    new_test_children = create_children(parents, reproducer, state; use_crossover = false)
    println("len new_test_children = ", length(new_test_children))
    println("len new_test_population = ", length(new_test_population))
    retiree_candidates = [retiree for retiree in ecosystem.retired_tests if !(retiree in new_test_population)]
    n_active_retirees = min(length(retiree_candidates), n_active_retirees)
    active_retirees = sample(retiree_candidates, n_active_retirees, replace = false)
    println("len active_retirees = ", length(active_retirees))
    misc_tests = [active_retirees ; new_test_children]
    if length(new_test_population) != length(ecosystem.test_population)
        error("LENGTHS = ", length(new_test_population), " ", length(ecosystem.test_population))
    end
    #I = typeof(first(new_learner_population))
    #return I[], [new_archive_children ; new_learner_children]
    return new_test_population, misc_tests
end
    ##n_random_immigrants = div(ecosystem_creator.n_learner_children, 4)
    #n_random_immigrants = 25
    #random_immigrants = create_children(
    #    sample(new_test_population, n_random_immigrants, replace = true), reproducer, state; use_crossover = false
    #)
    #for immigrant in random_immigrants
    #    for i in eachindex(immigrant.genotype.genes)
    #        immigrant.genotype.genes[i] = rand(0:1)
    #    end
    #end
    #println("len random immigrants = ", length(random_immigrants))
    #misc_tests = [active_retirees ; random_immigrants; new_test_children]

    #for _ in 1:5
    #    competitors = sample(new_test_population, 3, replace = false)
    #    id_scores = [
    #        learner => sum(evaluation.learner_score_matrix[learner.id, :]) 
    #        for learner in competitors
    #    ]
    #    parent = first(reduce(
    #        (id_score_1, id_score_2) -> id_score_1[2] > id_score_2[2] ? 
    #        id_score_1 : id_score_2, 
    #        shuffle(id_scores)
    #    ))
    #    push!(parents, parent)
    #end
    #new_learner_children = create_children(parents, reproducer, state)
    #for _ in 1:5
    #    popfirst!(new_learner_population)
    #end
