export MaxSolveEcosystem, MaxSolveEcosystemCreator, MaxSolveEvaluation
export create_ecosystem, update_ecosystem!, evaluate, make_all_matches
export get_all_individuals, select_individuals_aggregate, create_performance_matrix
export initialize_learners, initialize_tests, create_children, update_learners
export run_tournament

import ....Interfaces: make_all_matches
using ....Interfaces
using ....Abstract
using ...Matrices.Outcome
using ...Matches.Basic
using ...Genotypes.FiniteStateMachines

Base.@kwdef mutable struct MaxSolveEcosystem{I <: Individual, M <: OutcomeMatrix} <: Ecosystem
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

Base.@kwdef struct MaxSolveEcosystemCreator <: EcosystemCreator 
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


function get_all_individuals(ecosystem::MaxSolveEcosystem{I, M}) where {I, M}
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
using ...Recombiners.Clone: CloneRecombiner
using ...Phenotypes.Defaults: DefaultPhenotypeCreator

function create_children(parents::Vector{<:Individual}, reproducer::Reproducer, state::State; use_crossover::Bool = true)
    #recombiner = use_crossover ? reproducer.recombiner : CloneRecombiner()
    recombiner = CloneRecombiner()
    children = recombine(
        recombiner, reproducer.mutator, reproducer.phenotype_creator, parents, state
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
    if eco_creator.learner_algorithm == "p_phc_uni"
        for individual in learner_population
            n_states = rand(state.rng, 1:8)
            new_genotype = create_random_fsm_genotype(n_states, state.gene_id_counter, state.rng)
            individual.genotype = new_genotype
            individual.phenotype = create_phenotype(DefaultPhenotypeCreator(), individual.id, individual.genotype)
        end
    end
    if eco_creator.learner_algorithm in ["p_phc", "p_phc_uni", "p_phc_p_frs", "p_phc_p_uhs"]
        learner_parents = learner_population
    else
        learner_parents = sample(
            state.rng, learner_population, eco_creator.n_learner_children, replace = true
        )
    end
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
    if eco_creator.test_algorithm == "p_phc_uni"
        for individual in test_population
            n_states = rand(state.rng, 1:8)
            new_genotype = create_random_fsm_genotype(n_states, state.gene_id_counter, state.rng)
            individual.genotype = new_genotype
            individual.phenotype = create_phenotype(
                DefaultPhenotypeCreator(), individual.id, individual.genotype
            )
        end
    end
    if eco_creator.test_algorithm in ["p_phc", "p_phc_uni", "p_phc_p_frs", "p_phc_p_uhs"]
        test_parents = test_population
    else
        test_parents = sample(
            state.rng, test_population, eco_creator.n_test_children, replace = true
        )
    end
    test_children = create_children(test_parents, reproducer, state; use_crossover=false)
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
    retiree_population, _  = initialize_tests(eco_creator, last(reproducers), state)
    #println("test_pop_ids = ", [test.id for test in test_population])
    #println("test_child_ids = ", [test.id for test in test_children])
    I = typeof(first(learner_population))
    payoff_matrix = OutcomeMatrix("L", Int[], Int[], fill(false, 0, 0))
    new_ecosystem = MaxSolveEcosystem(
        id = eco_creator.id, 
        learner_population = learner_population, 
        learner_children = learner_children,
        learner_archive = I[], 
        learner_retirees = I[],
        test_population = test_population, 
        test_children = test_children, 
        test_archive = I[], 
        retired_tests = I[],
        #retired_tests = retiree_population,
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
    sort!(id_scores, by=x-> (x[2], rand()), rev=true)
    selected_ids = [first(id_score) for id_score in id_scores[1:n]]
    selected_indivduals = [ecosystem[id] for id in selected_ids]
    return selected_indivduals
end

using ...Selectors.FitnessProportionate

function roulette(rng::AbstractRNG, n_spins::Int, fitnesses::Vector{<:Real})
    if any(fitnesses .<= 0)
        throw(ArgumentError("Fitness values must be strictly positive for FitnessProportionateSelector."))
    end
    probabilities = fitnesses ./ sum(fitnesses)
    cumulative_probabilities = cumsum(probabilities)
    winner_indices = Array{Int}(undef, n_spins)
    spins = rand(rng, n_spins)
    for (i, spin) in enumerate(spins)
        candidate_index = 1
        while cumulative_probabilities[candidate_index] < spin
            candidate_index += 1
        end
        winner_indices[i] = candidate_index
    end
    return winner_indices
end

struct MaxSolveEvaluation{
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
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator, 
    state::State
)
    println("------UPDATE ECOSYSTEM: GENERATION: $(state.generation) ------")
    reproducers = state.reproducers
    learner_evaluation = first(state.evaluations)

    if ecosystem_creator.learner_algorithm == "doc"
        new_learner_population, new_learner_children = update_learners_doc(
            reproducers[1], learner_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.learner_algorithm == "tourn"
        new_learner_population, new_learner_children = update_learners_tourn(
            reproducers[1], learner_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.learner_algorithm == "roulette"
        new_learner_population, new_learner_children = update_learners_roulette(
            reproducers[1], learner_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.learner_algorithm == "control"
        new_learner_population, new_learner_children = update_learners_control(
            reproducers[1], learner_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.learner_algorithm in ["p_phc", "p_phc_uni"]
        new_learner_population, new_learner_children = update_learners_p_phc(
            reproducers[1], learner_evaluation, ecosystem, ecosystem_creator, state
        )   
    elseif ecosystem_creator.learner_algorithm == "p_phc_p_frs"
        new_learner_population, new_learner_children = update_learners_p_phc_p_frs(
            reproducers[1], learner_evaluation, ecosystem, ecosystem_creator, state
        )   
    elseif ecosystem_creator.learner_algorithm == "p_phc_p_uhs"
        new_learner_population, new_learner_children = update_learners_p_phc_p_uhs(
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
    elseif ecosystem_creator.test_algorithm == "qmeu_alpha"
        new_test_population, new_test_children = update_tests_qmeu_alpha(
            reproducers[2], test_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.test_algorithm == "qmeu-beta"
        new_test_population, new_test_children = update_tests_qmeu_beta(
            reproducers[2], test_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.test_algorithm == "qmeu-gamma"
        new_test_population, new_test_children = update_tests_qmeu_gamma(
            reproducers[2], test_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.test_algorithm == "roulette"
        new_test_population, new_test_children = update_tests_roulette(
            reproducers[2], test_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.test_algorithm == "control"
        new_test_population, new_test_children = update_tests_control(
            reproducers[2], test_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.test_algorithm in ["p_phc", "p_phc_uni"]
        new_test_population, new_test_children = update_tests_p_phc(
            reproducers[2], test_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.test_algorithm == "p_phc_p_frs"
        new_test_population, new_test_children = update_tests_p_phc_p_frs(
            reproducers[2], test_evaluation, ecosystem, ecosystem_creator, state
        )
    elseif ecosystem_creator.test_algorithm == "p_phc_p_uhs"
        new_test_population, new_test_children = update_tests_p_phc_p_uhs(
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
    #W = typeof(first(outcomes).outcome)
    if length(filtered_outcomes) != length(ids) * length(other_ids)
        error("length(filtered_outcomes) = $(length(filtered_outcomes)), length(ids) = $(length(ids)), length(other_ids) = $(length(other_ids))")
    end
    payoff_matrix = OutcomeMatrix{Bool}(species_id, ids, other_ids)
    for outcome in filtered_outcomes
        payoff_matrix[outcome.id, outcome.other_id] = Bool(outcome.outcome)
    end
    return payoff_matrix
end

include("covered.jl")

function MaxSolveEvaluation(
    species_id::String, 
    row_ids::Vector{Int}, 
    column_ids::Vector{Int},
    ecosystem::MaxSolveEcosystem, 
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
    payoff_dodo_evaluation = evaluate_dodo(ecosystem, payoff_matrix, state, "$(species_id)-P")
    distinction_dodo_evaluation = payoff_dodo_evaluation
    evaluation = MaxSolveEvaluation(
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
    ecosystem::MaxSolveEcosystem, 
    evaluators::Vector{<:Evaluator}, 
    results::Vector{<:Result}, 
    state::State
)
    println("-----EVALUATION GEN: $(state.generation)")
    t = time()
    outcomes = vcat([get_individual_outcomes(result) for result in results]...)
    row_ids = [learner.id for learner in [
        ecosystem.learner_population; ecosystem.learner_children#; ecosystem.learner_archive
    ]]
    column_ids = [test.id for test in [
        ecosystem.test_population; ecosystem.test_children #; ecosystem.test_archive
    ]]
    learner_evaluation = MaxSolveEvaluation(
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
        ecosystem.test_population; ecosystem.test_children #; ecosystem.test_archive
    ]]
    column_ids = [learner.id for learner in [
        ecosystem.learner_population; ecosystem.learner_children #; ecosystem.learner_archive
    ]]

    test_evaluation = MaxSolveEvaluation(
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
    #return [evaluation, learner_dodo_evaluation, test_dodo_evaluation]
end
