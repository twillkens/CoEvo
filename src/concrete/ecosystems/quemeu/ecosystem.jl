export QueMEUEcosystem, QueMEUEcosystemCreator, QueMEUEvaluation
export create_ecosystem, update_ecosystem!, evaluate, make_all_matches
export get_all_individuals, select_individuals_aggregate, create_performance_matrix
export initialize_learners, initialize_tests, create_children, update_learners, update_tests
export run_tournament

import ....Interfaces: make_all_matches
using ....Interfaces
using ....Abstract
using ...Matrices.Outcome
using ...Matches.Basic

Base.@kwdef mutable struct QueMEUEcosystem{I <: Individual, M <: OutcomeMatrix} <: Ecosystem
    id::Int
    learner_population::Vector{I}
    learner_children::Vector{I}
    learner_archive::Vector{I}
    learner_retirees::Vector{I}
    test_population::Vector{I}
    test_children::Vector{I}
    test_archive::Vector{I}
    retired_tests::Vector{I}
    payoff_matrix::M
end

Base.@kwdef struct QueMEUEcosystemCreator <: EcosystemCreator 
    id::Int = 1
    n_learner_population::Int = 20
    n_learner_children::Int = 20
    n_test_population::Int = 20
    n_test_children::Int = 20
    max_learner_archive_size::Int = 10
    learner_algorithm::String = "standard"
    test_algorithm::String = "standard"
end

Base.@kwdef mutable struct NewDodoRecord{I <: Individual} <: Record
    id::Int = 0
    individual::I
    raw_outcomes::Vector{Float64} = Float64[]
    filtered_outcomes::Vector{Float64} = Float64[]
    outcomes::Vector{Float64} = Float64[]
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
end

Base.@kwdef struct NewDodoEvaluation{
    R <: NewDodoRecord, M1 <: OutcomeMatrix, M2 <: OutcomeMatrix, M3 <: OutcomeMatrix
} <: Evaluation
    id::String
    cluster_leader_ids::Vector{Int}
    farthest_first_ids::Vector{Int}
    raw_matrix::M1
    filtered_matrix::M2
    matrix::M3
    records::Vector{R}
end


function get_all_individuals(ecosystem::QueMEUEcosystem{I, M}) where {I, M}
    individuals = unique([
        ecosystem.learner_archive ; 
        ecosystem.learner_children ;
        ecosystem.learner_population ; 
        ecosystem.test_population
        ecosystem.test_children ;
        ecosystem.test_archive ; 
        ecosystem.retired_tests
    ])
    
    return individuals
end

function Base.getindex(ecosystem::QueMEUEcosystem, individual_id::Int)
    all_individuals = get_all_individuals(ecosystem)
    individual = find_by_id(all_individuals, individual_id)
    if individual === nothing
        error("individual_id = $individual_id not found in ecosystem")
    end
    return individual
end

Base.getindex(ecosystem::QueMEUEcosystem, species_id::String) = begin
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
using ...Recombiners.Clone: CloneRecombiner

function create_children(parents::Vector{<:Individual}, reproducer::Reproducer, state::State; use_crossover::Bool = true)
    recombiner = CloneRecombiner()
    children = recombine(
        recombiner, reproducer.mutator, reproducer.phenotype_creator, parents, state
    )
    return children
end

function initialize_learners(
    eco_creator::QueMEUEcosystemCreator, reproducer::Reproducer, state::State
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
    eco_creator::QueMEUEcosystemCreator, reproducer::Reproducer, state::State
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
    test_children = create_children(test_parents, reproducer, state; use_crossover=false)
    return test_population, test_children
end

function create_ecosystem(
    eco_creator::QueMEUEcosystemCreator, reproducers::Vector{<:Reproducer}, state::State
)
    if length(reproducers) != 2
        error("length(reproducers) = $(length(reproducers)), expected 2")
    end

    learner_population, learner_children = initialize_learners(eco_creator, first(reproducers), state)
    test_population, test_children = initialize_tests(eco_creator, last(reproducers), state)
    I = typeof(first(learner_population))
    payoff_matrix = OutcomeMatrix("L", Int[], Int[], fill(false, 0, 0))
    new_ecosystem = QueMEUEcosystem(
        id = eco_creator.id, 
        learner_population = learner_population, 
        learner_children = learner_children,
        learner_archive = I[], 
        learner_retirees = I[],
        test_population = test_population, 
        test_children = test_children, 
        test_archive = I[], 
        retired_tests = I[],
        payoff_matrix = payoff_matrix
    )
    return new_ecosystem
end

function select_individuals_aggregate(
    ecosystem::QueMEUEcosystem, score_matrix::OutcomeMatrix, n::Int
)
    id_scores = [id => sum(score_matrix[id, :]) for id in score_matrix.row_ids]
    sort!(id_scores, by=x-> (x[2], rand()), rev=true)
    selected_ids = [first(id_score) for id_score in id_scores[1:n]]
    selected_indivduals = [ecosystem[id] for id in selected_ids]
    return selected_indivduals
end

struct QueMEUEvaluation{
    T <: OutcomeMatrix, U <: OutcomeMatrix, V <: OutcomeMatrix
} <: Evaluation
    id::String
    full_payoff_matrix::T
    payoff_matrix::T
    distinction_matrix::U
    standard_score_matrix::V
    advanced_score_matrix::V
    payoff_dodo_evaluation::NewDodoEvaluation
    distinction_dodo_evaluation::NewDodoEvaluation
end

include("learners.jl")
include("tests.jl")

function update_ecosystem!(
    ecosystem::QueMEUEcosystem, 
    ecosystem_creator::QueMEUEcosystemCreator, 
    state::State
)
    println("------UPDATE ECOSYSTEM: GENERATION: $(state.generation) ------")
    reproducers = state.reproducers
    learner_evaluation = first(state.evaluations)

    if ecosystem_creator.learner_algorithm == "disco"
        new_learner_population, new_learner_children = update_learners_disco(
            reproducers[1], learner_evaluation, ecosystem, ecosystem_creator, state
        )
    else
        error("Invalid learner algorithm: $(ecosystem_creator.learner_algorithm)")
    end
    ecosystem.learner_population = new_learner_population
    ecosystem.learner_children = new_learner_children

    test_evaluation = last(state.evaluations)

    println("Using test algorithm: $(ecosystem_creator.test_algorithm)")
    if ecosystem_creator.test_algorithm == "standard"
        new_test_population, new_test_children = update_tests_standard_distinctions(
            reproducers[2], test_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.test_algorithm == "advanced"
        new_test_population, new_test_children = update_tests_advanced(
            reproducers[2], test_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.test_algorithm == "qmeu"
        new_test_population, new_test_children = update_tests_quemeu(
            reproducers[2], test_evaluation, ecosystem, ecosystem_creator, state
        )
    else
        error("Invalid test algorithm: $(ecosystem_creator.test_algorithm)")
    end
    ecosystem.test_population = new_test_population
    ecosystem.test_children = new_test_children
    println("length_learner_population = ", length(new_learner_population))
    println("length_learner_children = ", length(new_learner_children))
    println("length_learner_archive = ", length(ecosystem.learner_archive))
    println("length_learner_retirees = ", length(ecosystem.learner_retirees))

    println("length_test_population = ", length(new_test_population))
    println("length_test_children = ", length(new_test_children))
    println("length_test_archive = ", length(ecosystem.test_archive))
    println("length_test_retirees = ", length(ecosystem.retired_tests))
end


function create_performance_matrix(species_id::String, outcomes::Vector{<:Result})
    filtered_outcomes = filter(x -> x.species_id == species_id, outcomes)
    ids = sort(unique([outcome.id for outcome in filtered_outcomes]))
    other_ids = sort(unique([outcome.other_id for outcome in filtered_outcomes]))
    if length(filtered_outcomes) != length(ids) * length(other_ids)
        error("length(filtered_outcomes) = $(length(filtered_outcomes)), length(ids) = $(length(ids)), length(other_ids) = $(length(other_ids))")
    end
    payoff_matrix = OutcomeMatrix{Bool}(species_id, ids, other_ids)
    for outcome in filtered_outcomes
        payoff_matrix[outcome.id, outcome.other_id] = Bool(outcome.outcome)
    end
    return payoff_matrix
end

function QueMEUEvaluation(
    species_id::String, 
    row_ids::Vector{Int}, 
    column_ids::Vector{Int},
    ecosystem::QueMEUEcosystem, 
    outcomes::Vector{<:Result}, 
    state::State;
    performance_weight::Float64 = 3.0,
    distinction_weight::Float64 = 1.0
)
    full_payoff_matrix = create_performance_matrix(species_id, outcomes)
    payoff_matrix = filter_rows(full_payoff_matrix, row_ids)
    payoff_matrix = filter_columns(payoff_matrix, column_ids)
    distinction_matrix = make_full_distinction_matrix(payoff_matrix)
    standard_score_matrix = evaluate_standard(payoff_matrix)
    advanced_score_matrix = evaluate_advanced(payoff_matrix, performance_weight, distinction_weight)
    println("----EVALUATING FOR $(species_id)----P")
    payoff_dodo_evaluation = evaluate_dodo(ecosystem, payoff_matrix, state, "$(species_id)-P")
    println("----EVALUATING FOR $(species_id)----D")
    distinction_dodo_evaluation = payoff_dodo_evaluation
    evaluation = QueMEUEvaluation(
        species_id, 
        full_payoff_matrix,
        payoff_matrix, 
        distinction_matrix, 
        standard_score_matrix, 
        advanced_score_matrix, 
        payoff_dodo_evaluation, 
        distinction_dodo_evaluation
    )
    return evaluation

end

function evaluate(
    ecosystem::QueMEUEcosystem, 
    evaluators::Vector{<:Evaluator}, 
    results::Vector{<:Result}, 
    state::State
)
    println("-----EVALUATION GEN: $(state.generation)")
    t = time()
    outcomes = vcat([get_individual_outcomes(result) for result in results]...)
    row_ids = [learner.id for learner in [
        ecosystem.learner_population; ecosystem.learner_children
    ]]
    column_ids = [test.id for test in [
        ecosystem.test_population; ecosystem.test_children 
    ]]
    learner_evaluation = QueMEUEvaluation(
        "L", 
        row_ids, 
        column_ids, 
        ecosystem, 
        outcomes, 
        state,
        performance_weight = 1.0,
        distinction_weight = 0.0
    )

    row_ids = [test.id for test in [
        ecosystem.test_population; ecosystem.test_children 
    ]]
    column_ids = [learner.id for learner in [
        ecosystem.learner_population; ecosystem.learner_children 
    ]]

    test_evaluation = QueMEUEvaluation(
        "T", 
        row_ids, 
        column_ids, 
        ecosystem, 
        outcomes, 
        state;
        performance_weight = 3.0,
        distinction_weight = 1.0
    )

    println("evaluation time = ", time() - t)
    ecosystem.payoff_matrix = learner_evaluation.full_payoff_matrix
    return [learner_evaluation, test_evaluation]
end
