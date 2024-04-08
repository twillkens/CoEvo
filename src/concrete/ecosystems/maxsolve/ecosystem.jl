export MaxSolveEcosystem, MaxSolveEcosystemCreator, MaxSolveEvaluation
export create_ecosystem, update_ecosystem!, evaluate, make_all_matches
export get_all_individuals, create_performance_matrix
export create_children
export run_tournament

import ....Interfaces: make_all_matches, update_species!

using ...Ecosystems.Simple: SimpleEcosystem
using ...Species.Basic: BasicSpecies
using ...Recombiners.Clone: CloneRecombiner

using ....Interfaces
using ....Abstract
using ...Matrices.Outcome
using ...Matches.Basic

Base.@kwdef mutable struct MaxSolveSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    children::Vector{I}
    archive::Vector{I}
    retirees::Vector{I}
end

function get_all_individuals(species::MaxSolveSpecies)
    return unique([species.population ; species.children ; species.archive ; species.retirees])
end

Base.@kwdef mutable struct MaxSolveEcosystem{S <: MaxSolveSpecies} <: Ecosystem
    id::Int
    learners::S
    tests::S
end

function get_all_individuals(ecosystem::MaxSolveEcosystem)
    return unique([get_all_individuals(ecosystem.learners) ; get_all_individuals(ecosystem.tests)])
end

Base.@kwdef struct MaxSolveEcosystemCreator <: EcosystemCreator 
    id::Int = 1
    # Learner Parameters
    n_learner_population::Int = 20
    n_learner_parents::Int = 20
    n_learner_children::Int = 20
    learner_retiree_archive_size::Int = 0

    # Test Parameters
    n_test_population::Int = 20
    n_test_parents::Int = 20
    n_test_children::Int = 20
    test_retiree_archive_size::Int = 1000

    # Algorithm Parameters
    algorithm::String = "standard"
    max_learner_archive_size::Int = 10
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

function Base.getindex(ecosystem::MaxSolveEcosystem, individual_id::Int)
    all_individuals = get_all_individuals(ecosystem)
    #println("all_ids = ", [individual.id for individual in all_individuals])
    individual = find_by_id(all_individuals, individual_id)
    if individual === nothing
        error("individual_id = $individual_id not found in ecosystem")
    end
    return individual
end

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
    reproducer::Reproducer, 
    n_population::Int,
    n_parents::Int,
    n_children::Int,
    state::State
)
    population = create_individuals(
        reproducer.individual_creator, 
        n_population,
        reproducer, 
        state
    )
    parents = sample(population, n_parents, replace = true)
    children = create_children(n_children, parents, reproducer, state)
    return population, children
end


function create_ecosystem(
    eco_creator::MaxSolveEcosystemCreator, reproducers::Vector{<:Reproducer}, state::State
)
    if length(reproducers) != 2
        error("length(reproducers) = $(length(reproducers)), expected 2")
    end
    learner_population, learner_children = initialize_population_and_children(
        first(reproducers), 
        eco_creator.n_learner_population, 
        eco_creator.n_learner_parents, 
        eco_creator.n_learner_children, 
        state
    )
    test_population, test_children = initialize_population_and_children(
        last(reproducers), 
        eco_creator.n_test_population, 
        eco_creator.n_test_parents, 
        eco_creator.n_test_children, 
        state
    )

    I = typeof(first(learner_population))
    learners = MaxSolveSpecies("L", learner_population, learner_children, I[], I[])
    tests = MaxSolveSpecies("T", test_population, test_children, I[], I[])
    new_ecosystem = MaxSolveEcosystem(
        id = eco_creator.id, 
        learners = learners,
        tests = tests
    )
    return new_ecosystem
end

struct MaxSolveEvaluation{
    T <: OutcomeMatrix, U <: OutcomeMatrix, V <: OutcomeMatrix
} <: Evaluation
    id::String
    payoff_matrix::T
    distinction_matrix::U
    #standard_score_matrix::V
    #advanced_score_matrix::V
    #payoff_dodo_evaluation::NewDodoEvaluation
    #distinction_dodo_evaluation::NewDodoEvaluation
end

include("learners.jl")
include("tests.jl")

function update_maxsolve_archive!(
    ecosystem_creator::MaxSolveEcosystemCreator, 
    ecosystem::MaxSolveEcosystem, 
    payoff_matrix::OutcomeMatrix
)
    if ecosystem_creator.maxsolve_archive_size > 0
        maxsolve_matrix = maxsolve(payoff_matrix, ecosystem_creator.maxsolve_archive_size)
        new_learner_archive = [ecosystem[learner_id] for learner_id in maxsolve_matrix.row_ids]
        retired_learners = [
            learner for learner in ecosystem.learner_archive if learner.id ∉ maxsolve_matrix.row_ids
        ]
        append!(ecosystem.learner_retirees, retired_learners)
        while length(ecosystem.learner_retirees) > 1000
            popfirst!(ecosystem.learner_retirees)
        end

        new_test_archive = [ecosystem[test_id] for test_id in maxsolve_matrix.column_ids]
        test_retirees = [
            test for test in ecosystem.test_archive if test.id ∉ maxsolve_matrix.column_ids
        ]
        append!(ecosystem.test_retirees, test_retirees)
        while length(ecosystem.test_retirees) > 1000
            popfirst!(ecosystem.test_retirees)
        end

        ecosystem.learner_archive = new_learner_archive
        ecosystem.test_archive = new_test_archive
    end
end

function print_pop_lengths(ecosystem::MaxSolveEcosystem)
    println(
        "LEARNERS LENGTH: population = ", length(ecosystem.learners.population), 
        ", children = ", length(ecosystem.learners.children), 
        ", archive = ", length(ecosystem.learners.archive), 
        ", retirees = ", length(ecosystem.learners.retirees)
    )
    println(
        "TESTS LENGTH: population = ", length(ecosystem.tests.population), 
        ", children = ", length(ecosystem.tests.children), 
        ", archive = ", length(ecosystem.tests.archive), 
        ", retirees = ", length(ecosystem.tests.retirees)
    )
end

["standard_outcome", "competitive_outcome", "standard_distinction", "competitive_distinction"]

Base.@kwdef struct ScoreParameters
    zero_out_duplicate_rows::Bool
    competitive_sharing::Bool
    weight::Float64
end

abstract type SpeciesScoreParameters end

Base.@kwdef struct EvolutionStrategyParameters <: SpeciesScoreParameters
    outcomes::ScoreParameters
    distinctions::ScoreParameters
end

Base.@kwdef struct DiscoScoreParameters <: SpeciesScoreParameters
    use_outcomes::Bool = true
    n_clusters::Int = 5
end

Base.@kwdef struct DodoParameters <: SpeciesScoreParameters
    outcomes::ScoreParameters
    distinctions::ScoreParameters
end

Base.@kwdef struct EcosystemScoreParameters{
    L <: SpeciesScoreParameters, T <: SpeciesScoreParameters
}
    learners::L
    tests::T
end

Base.@kwdef struct StandardParameters{
    L <: SpeciesScoreParameters, T <: SpeciesScoreParameters
}
    learners::L
    tests::T
end

SCORE_PARAMS = Dict(
    "standard" => EcosystemScoreParameters(
        learners = EvolutionStrategyParameters(
            outcomes = ScoreParameters(false, false, 1.0), 
            distinctions = ScoreParameters(false, false, 0.0)
        ),
        tests = EvolutionStrategyParameters(
            outcomes = ScoreParameters(false, false, 1.0), 
            distinctions = ScoreParameters(false, false, 0.0)
        )
    ),
    "cel" => EcosystemScoreParameters(
        learners = EvolutionStrategyParameters(
            outcomes = ScoreParameters(false, false, 1.0), 
            distinctions = ScoreParameters(false, false, 0.0)
        ),
        tests = EvolutionStrategyParameters(
            outcomes = ScoreParameters(false, false, 0.0), 
            distinctions = ScoreParameters(false, false, 1.0)
        )
    ),
    "advanced" => EcosystemScoreParameters(
        learners = EvolutionStrategyParameters(
            outcomes = ScoreParameters(true, true, 3.0), 
            distinctions = ScoreParameters(true, true, 1.0)
        ),
        tests = EvolutionStrategyParameters(
            outcomes = ScoreParameters(true, true, 3.0), 
            distinctions = ScoreParameters(true, true, 1.0)
        )
    ), 
    "disco" => EcosystemScoreParameters(
        learners = DiscoScoreParameters(),
        tests = EvolutionStrategyParameters(
            outcomes = ScoreParameters(false, false, 0.0), 
            distinctions = ScoreParameters(false, false, 1.0)
        )
    ),
    "dodo" => EcosystemScoreParameters(
        learners = DiscoScoreParameters(),
        tests = DodoParameters(
            outcomes = ScoreParameters(false, false, 0.0), 
            distinctions = ScoreParameters(true, true, 1.0)
        )
    )
)
function get_ids_truncation_replacement(
    score_matrix::OutcomeMatrix, n::Int, rng::AbstractRNG = Random.GLOBAL_RNG
)
    if length(score_matrix.column_ids) > 1
        error("Truncation selection only works with a single column for scalar fitness")
    end
    id_scores = [id => first(score_matrix[id, :]) for id in score_matrix.row_ids]
    sort!(id_scores, by=x-> (x[2], rand(rng)), rev=true)
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
    zero_out_duplicate_rows::Bool, 
    competitive_sharing::Bool, 
    weight::Float64,
    rng::AbstractRNG = Random.GLOBAL_RNG
)
    matrix = zero_out_duplicate_rows ? zero_out_duplicate_rows(matrix, rng) : matrix
    matrix = competitive_sharing ? make_competitive_sum_matrix(matrix) : make_standard_sum_matrix(matrix)
    matrix.data = matrix.data .* weight
    return matrix
end

function get_score_matrix(matrix::OutcomeMatrix, params::ScoreParameters, rng::AbstractRNG)
    return get_score_matrix(
        matrix, params.zero_out_duplicate_rows, params.competitive_sharing, params.weight
    )
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

function update_species!(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    species_params::EvolutionStrategyParameters,
    species::MaxSolveSpecies,
    n_parents::Int,
    n_children::Int,
    state::State
)
    population, children = species.population, species.children
    outcome_scores = get_score_matrix(
        evaluation.payoff_matrix, species_params.outcomes, state.rng
    )
    distinction_scores = get_score_matrix(
        evaluation.distinction_matrix, species_params.distinctions, state.rng
    )
    total_scores = add_matrices(outcome_scores, distinction_scores)
    candidates = [population ; children]
    candidate_ids = [candidate.id for candidate in candidates]
    if Set(candidate_ids) != Set(total_scores.row_ids)
        error("candidate_ids = $candidate_ids, matrix.row_ids = $(total_scores.row_ids)")
    end
    population_ids = get_ids_truncation_replacement(total_scores, length(population), state.rng)
    new_population = [candidate for candidate in candidates if candidate.id in population_ids]
    parents = sample(state.rng, new_population, n_parents, replace = true)
    new_children = create_children(n_children, parents, reproducer, state)
    empty!(population)
    append!(population, new_population)
    empty!(children)
    append!(children, new_children)
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
        first(state.reproducers),
        learner_evaluation, 
        parameters.learners, 
        ecosystem.learners, 
        ecosystem_creator.n_learner_parents, 
        ecosystem_creator.n_learner_children, 
        state
    )
    update_species!(
        last(state.reproducers),
        test_evaluation, 
        parameters.tests, 
        ecosystem.tests, 
        ecosystem_creator.n_test_parents, 
        ecosystem_creator.n_test_children, 
        state
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
        parameters, 
        ecosystem, 
        ecosystem_creator, 
        learner_evaluation, 
        test_evaluation, 
        state
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

function MaxSolveEvaluation(
    species_id::String, 
    outcomes::Vector{<:Result}, 
)
    outcome_matrix = create_outcome_matrix(species_id, outcomes)
    distinction_matrix = make_full_distinction_matrix(outcome_matrix)
    #payoff_matrix = filter_rows(full_payoff_matrix, row_ids)
    #payoff_matrix = filter_columns(payoff_matrix, column_ids)
    #standard_score_matrix = evaluate_standard(payoff_matrix)
    #advanced_score_matrix = evaluate_advanced(payoff_matrix, performance_weight, distinction_weight)
    #println("----EVALUATING DODO FOR $(species_id)----P")
    #payoff_dodo_evaluation = evaluate_dodo(ecosystem, payoff_matrix, state, "$(species_id)-P")
    #println("----EVALUATING DODO FOR $(species_id)----D")
    #distinction_dodo_evaluation = payoff_dodo_evaluation
    ##distinction_dodo_evaluation = evaluate_dodo(ecosystem, distinction_matrix, state, "$(species_id)-D")
    evaluation = MaxSolveEvaluation(
        species_id, 
        outcome_matrix, 
        distinction_matrix, 
    )
    return evaluation

end

function evaluate(
    ::MaxSolveEcosystem, 
    ::Vector{<:Evaluator}, 
    results::Vector{<:Result}, 
    ::State
)
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