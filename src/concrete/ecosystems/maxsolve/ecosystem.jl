export MaxSolveEcosystem, MaxSolveEcosystemCreator, MaxSolveEvaluation
export create_ecosystem, update_ecosystem!, evaluate, make_all_matches
export get_all_individuals, select_individuals_aggregate, create_performance_matrix
export initialize_learners, initialize_tests, create_children, update_learners, update_tests

import ....Interfaces: make_all_matches
using ....Interfaces
using ....Abstract
using ...Matrices.Outcome
using ...Matches.Basic

Base.@kwdef mutable struct MaxSolveEcosystem{I <: Individual, M <: OutcomeMatrix} <: Ecosystem
    id::Int
    learner_population::Vector{I}
    learner_children::Vector{I}
    learner_archive::Vector{I}
    test_population::Vector{I}
    test_children::Vector{I}
    test_archive::Vector{I}
    retired_tests::Vector{I}
    payoff_matrix::M
end

Base.@kwdef struct MaxSolveEcosystemCreator <: EcosystemCreator 
    id::Int = 1
    n_learner_population::Int = 20
    n_learner_children::Int = 20
    n_test_population::Int = 20
    n_test_children::Int = 20
    max_learner_archive_size::Int = 10
end

struct MaxSolveEvaluation{
    T <: OutcomeMatrix, U <: OutcomeMatrix, V <: OutcomeMatrix
} <: Evaluation
    id::Int
    full_payoff_matrix::T
    learner_score_matrix::U
    test_score_matrix::V
end


function get_all_individuals(ecosystem::MaxSolveEcosystem{I, M}) where {I, M}
    individuals = unique([
        ecosystem.learner_archive ; 
        ecosystem.learner_children ;
        ecosystem.learner_population ; 
        ecosystem.test_population
        ecosystem.test_children ;
        ecosystem.test_archive ; 
    ])
    
    return individuals
end

function Base.getindex(ecosystem::MaxSolveEcosystem, individual_id::Int)
    all_individuals = get_all_individuals(ecosystem)
    #println("all_ids = ", [individual.id for individual in all_individuals])
    individual = find_by_id(all_individuals, individual_id)
    if individual === nothing
        error("individual_id = $individual_id not found in ecosystem")
    end
    return individual
end

Base.getindex(ecosystem::MaxSolveEcosystem, species_id::String) = begin
    if species_id == "L"
        return ecosystem.learner_population
    elseif species_id == "T"
        return ecosystem.test_population
    elseif species_id == "LA"
        return ecosystem.learner_archive
    elseif species_id == "TA"
        return ecosystem.test_archive
    else
        error("species_id = $species_id not found in ecosystem")
    end
end

using ...Ecosystems.Simple: SimpleEcosystem
using ...Species.Basic: BasicSpecies

function create_children(parents::Vector{<:Individual}, reproducer::Reproducer, state::State)
    children = recombine(
        reproducer.recombiner, reproducer.mutator, reproducer.phenotype_creator, parents, state
    )
    return children
end

function initialize_learners(
    eco_creator::MaxSolveEcosystemCreator, reproducer::Reproducer, state::State
)
    learner_population = create_individuals(
        reproducer.individual_creator, 
        eco_creator.n_learner_population, 
        reproducer, 
        state
    )
    learner_parents = sample(
        learner_population, eco_creator.n_learner_children, replace = true
    )
    learner_children = create_children(learner_parents, reproducer, state)
    return learner_population, learner_children
end

function initialize_tests(
    eco_creator::MaxSolveEcosystemCreator, reproducer::Reproducer, state::State
)
    test_population = create_individuals(
        reproducer.individual_creator, 
        eco_creator.n_test_population, 
        reproducer, 
        state
    )
    test_parents = sample(
        test_population, eco_creator.n_test_children, replace = true
    )
    test_children = create_children(test_parents, reproducer, state)
    return test_population, test_children
end

function create_ecosystem(
    eco_creator::MaxSolveEcosystemCreator, reproducers::Vector{<:Reproducer}, state::State
)
    if length(reproducers) != 2
        error("length(reproducers) = $(length(reproducers)), expected 2")
    end

    learner_population, learner_children = initialize_learners(eco_creator, first(reproducers), state)
    #println("learner_pop_ids = ", [learner.id for learner in learner_population])
    #println("learner_child_ids = ", [learner.id for learner in learner_children])
    test_population, test_children = initialize_tests(eco_creator, last(reproducers), state)
    #println("test_pop_ids = ", [test.id for test in test_population])
    #println("test_child_ids = ", [test.id for test in test_children])
    I = typeof(first(learner_population))
    payoff_matrix = OutcomeMatrix("L", Int[], Int[], fill(false, 0, 0))
    new_ecosystem = MaxSolveEcosystem(
        id = eco_creator.id, 
        learner_population = learner_population, 
        learner_children = learner_children,
        learner_archive = I[], 
        test_population = test_population, 
        test_children = test_children, 
        test_archive = I[], 
        retired_tests = I[],
        payoff_matrix = payoff_matrix
    )
    return new_ecosystem
end

function validate_ecosystem(ecosystem::MaxSolveEcosystem, state::State)
    #all_individuals = [
    #    individual for species in ecosystem.all_species for individual in species.population
    #]
    #all_individual_ids = [individual.id for individual in all_individuals]
    #if length(all_individuals) != length(Set(all_individual_ids))
    #    println("all_individual_ids = $all_individual_ids")
    #    error("individual ids are not unique AFTER")
    #end
end

function select_individuals_aggregate(
    ecosystem::MaxSolveEcosystem, score_matrix::OutcomeMatrix, n::Int
)
    id_scores = [id => sum(score_matrix[id, :]) for id in score_matrix.row_ids]
    sort!(id_scores, by=x->x[2], rev=true)
    selected_ids = [first(id_score) for id_score in id_scores[1:n]]
    selected_indivduals = [ecosystem[id] for id in selected_ids]
    return selected_indivduals
end

function update_learners(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_learner_population = select_individuals_aggregate(
        ecosystem, evaluation.learner_score_matrix, ecosystem_creator.n_learner_population
    )
    #n_sample_archive = min(length(ecosystem.learner_archive), 10)
    #n_sample_population = 40 - n_sample_archive # ecosystem_creator.n_learner_children
    n_sample_population = ecosystem_creator.n_learner_children
    #archive_parents = sample(
    #    ecosystem.learner_archive, n_sample_archive, replace = true
    #)
    #new_archive_children = create_children(archive_parents, reproducer, state)
    learner_parents = sample(
        new_learner_population, n_sample_population, replace = true
    )
    new_learner_children = create_children(learner_parents, reproducer, state)
    #I = typeof(first(new_learner_population))
    #return I[], [new_archive_children ; new_learner_children]
    return new_learner_population, new_learner_children
end

function update_learners_no_elites(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_learner_population = select_individuals_aggregate(
        ecosystem, evaluation.learner_score_matrix, ecosystem_creator.n_learner_population
    )
    #n_sample_archive = min(length(ecosystem.learner_archive), 10)
    n_sample_archive = length(ecosystem.learner_archive)
    archive_parents = sample(
        ecosystem.learner_archive, n_sample_archive, replace = true
    )
    new_archive_children = create_children(archive_parents, reproducer, state)
    n_sample_population = ecosystem_creator.n_learner_children + ecosystem_creator.n_learner_population - n_sample_archive
    learner_parents = sample(
        new_learner_population, n_sample_population, replace = true
    )
    new_learner_children = create_children(learner_parents, reproducer, state)
    I = typeof(first(new_learner_population))
    return I[], [new_archive_children ; new_learner_children]
    #return new_learner_population, new_learner_children
end

function update_learners_regularized(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_learner_population = copy(ecosystem.learner_population)
    append!(new_learner_population, ecosystem.learner_children)
    #push!(new_learner_population, first(ecosystem.learner_children))
    I = typeof(first(new_learner_population))
    parents = I[]
    for _ in 1:5
        competitors = sample(new_learner_population, 3, replace = false)
        id_scores = [
            learner => sum(evaluation.learner_score_matrix[learner.id, :]) 
            for learner in competitors
        ]
        parent = first(reduce(
            (id_score_1, id_score_2) -> id_score_1[2] > id_score_2[2] ? 
            id_score_1 : id_score_2, 
            id_scores
        ))
        push!(parents, parent)
    end
    new_learner_children = create_children(parents, reproducer, state)
    for _ in 1:5
        popfirst!(new_learner_population)
    end
    #I = typeof(first(new_learner_population))
    #return I[], [new_archive_children ; new_learner_children]
    if length(ecosystem.learner_population) != length(new_learner_population)
        error("length(ecosystem.learner_population) = $(length(ecosystem.learner_population)), length(new_learner_population) = $(length(new_learner_population))")
    end
    return new_learner_population, new_learner_children
end

function update_tests(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_test_population = select_individuals_aggregate(
        ecosystem, evaluation.test_score_matrix, ecosystem_creator.n_test_population
    )
    test_parents = sample(
        new_test_population, ecosystem_creator.n_test_children, replace = true
    )
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

function update_ecosystem!(
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator, 
    state::State
)
    reproducers = state.reproducers
    evaluation = first(state.evaluations)
    #new_learner_population, new_learner_children = update_learners(
    #    reproducers[1], evaluation, ecosystem, ecosystem_creator, state
    #)
    new_learner_population, new_learner_children = update_learners_no_elites(
        reproducers[1], evaluation, ecosystem, ecosystem_creator, state
    )
    #new_test_population, new_test_children = update_tests(
    #    reproducers[2], evaluation, ecosystem, ecosystem_creator, state
    #)
    new_test_population, new_test_children = update_tests_no_elites(
        reproducers[2], evaluation, ecosystem, ecosystem_creator, state
    )
    t = time()
    maxsolve_matrix = maxsolve(
        evaluation.full_payoff_matrix, ecosystem_creator.max_learner_archive_size
    )
    println("maxsolve time = ", time() - t)
    new_learner_archive = [ecosystem[learner_id] for learner_id in maxsolve_matrix.row_ids]

    new_test_archive = [ecosystem[test_id] for test_id in maxsolve_matrix.column_ids]
    retired_tests = [test for test in ecosystem.test_archive if test.id ∉ maxsolve_matrix.column_ids]
    append!(ecosystem.retired_tests, retired_tests)
    while length(ecosystem.retired_tests) > 1000
        popfirst!(ecosystem.retired_tests)
    end
    matrix = filter_rows(
        evaluation.full_payoff_matrix, 
        [learner.id for learner in [new_learner_population ; new_learner_archive]]
    )
    matrix = filter_columns(
        matrix, 
        [test.id for test in [new_test_population ; new_test_archive]]
    )
    ecosystem.learner_population = new_learner_population
    ecosystem.learner_children = new_learner_children
    ecosystem.learner_archive = new_learner_archive
    ecosystem.test_population = new_test_population
    ecosystem.test_children = new_test_children
    ecosystem.test_archive = new_test_archive
    ecosystem.payoff_matrix = matrix
    println("length_learner_population = ", length(new_learner_population))
    println("length_learner_children = ", length(new_learner_children))
    println("length_learner_archive = ", length(new_learner_archive))
    println("length_test_population = ", length(new_test_population))
    println("length_test_children = ", length(new_test_children))
    println("length_test_archive = ", length(new_test_archive))
    println("length_test_retirees = ", length(ecosystem.retired_tests))
    #println("--Generation $(state.generation)--\n")
    #for learner in new_learner_archive
    #    genes = round.(learner.genotype.genes, digits=3)
    #    print("learner_$(learner.id) = $genes, ")
    #end
    #println("--")
    #println("length_test_archive = ", length(new_test_archive), "\n")
    #for test in new_test_archive
    #    genes = round.(test.genotype.genes, digits=3)
    #    print("test_$(test.id) = $genes, ")
    #end
    #println()
end


function create_performance_matrix(species_id::String, outcomes::Vector{<:Result})
    filtered_outcomes = filter(x -> x.species_id == species_id, outcomes)
    ids = sort(unique([outcome.id for outcome in filtered_outcomes]))
    other_ids = sort(unique([outcome.other_id for outcome in filtered_outcomes]))
    #W = typeof(first(outcomes).outcome)
    payoff_matrix = OutcomeMatrix{Bool}(species_id, ids, other_ids)
    for outcome in filtered_outcomes
        payoff_matrix[outcome.id, outcome.other_id] = Bool(outcome.outcome)
    end
    return payoff_matrix
end

function evaluate(
    ecosystem::MaxSolveEcosystem, 
    evaluators::Vector{<:Evaluator}, 
    results::Vector{<:Result}, 
    state::State
)
    t = time()
    outcomes = vcat([get_individual_outcomes(result) for result in results]...)
    new_payoff_matrix = create_performance_matrix("L", outcomes)
    full_payoff_matrix = merge_matrices(ecosystem.payoff_matrix, new_payoff_matrix)
    learner_population_matrix = filter_rows(
        full_payoff_matrix, 
        [learner.id for learner in [ecosystem.learner_population; ecosystem.learner_children]]
    )   
    learner_score_matrix = evaluate_advanced(learner_population_matrix, 3.0, 1.0)
    #learner_score_matrix = evaluate_advanced(learner_population_matrix)

    test_payoff_matrix = transpose_and_invert(full_payoff_matrix)
    test_payoff_matrix = filter_rows(
        test_payoff_matrix, 
        [test.id for test in [ecosystem.test_population; ecosystem.test_children]]
    )
    test_payoff_matrix.id = "T"
    test_score_matrix = evaluate_advanced(test_payoff_matrix, 3.0, 1.0)
    #test_score_matrix = evaluate_advanced(test_payoff_matrix)

    evaluation = MaxSolveEvaluation(
        ecosystem.id, 
        full_payoff_matrix, 
        learner_score_matrix,
        test_score_matrix
    )
    println("evaluation time = ", time() - t)
    return [evaluation]
end
