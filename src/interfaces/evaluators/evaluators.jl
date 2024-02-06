export evaluate
export make_individual_tests, calculate_fitnesses, check_for_nan_in_fitnesses
export convert_to_sorteddict
export get_individuals
export make_outcome_matrix, append_outcome_matrix
export make_outcome_and_distinction_matrix, implement_competitive_fitness_sharing
export condense_outcomes_to_scalar
export make_distinction_matrix

using DataStructures: SortedDict
using ..Abstract

function evaluate(
    evaluator::Evaluator,
    species::AbstractSpecies,
    ecosystem::Ecosystem,
    outcomes::Dict{Int, Dict{Int, Float64}},
    state::State
)
    evaluator = typeof(evaluator)
    species = typeof(species)
    outcomes = typeof(outcomes)
    state = typeof(state)
    error("`evaluate` not implemented for $evaluator, $species, $outcomes, $state.")
end

function evaluate(
    evaluator::Evaluator,
    ecosystem::Ecosystem,
    results::Vector{<:Result},
    state::State
)
    evaluations = [
        evaluate(evaluator, species, ecosystem, results, state)
        for species in ecosystem.all_species
    ]
    return evaluations
end

function convert_to_sorteddict(dict::Dict{Int, Dict{Int, Float64}})
    sorted_outer = SortedDict{Int, SortedDict{Int, Float64}}()

    for (outer_key, inner_dict) in dict
        sorted_inner = SortedDict{Int, Float64}()
        for (inner_key, value) in inner_dict
            sorted_inner[inner_key] = value
        end
        sorted_outer[outer_key] = sorted_inner
    end

    return sorted_outer
end

function make_individual_tests(
    individuals::Vector{<:Individual},
    outcomes::Dict{Int, Dict{Int, Float64}}
)
    ids = Set(individual.id for individual in individuals)
    if length(ids) == 0
        return SortedDict{Int, Vector{Float64}}()
    end
    outcomes = Dict(filter(pair -> first(pair) in ids, collect(outcomes)))
    outcomes = convert_to_sorteddict(outcomes)
    individual_tests = SortedDict{Int, Vector{Float64}}(
        id => [pair.second for pair in outcomes[id]]
        for id in ids
    )
    return individual_tests
end

function make_outcome_matrix(
    outer_indivs::Vector{<:Individual},
    inner_indivs::Vector{<:Individual},
    results::Vector{<:Result};
    rev::Bool = false
)
    outer_ids = sort([individual.id for individual in outer_indivs])
    inner_ids = sort([individual.id for individual in inner_indivs])
    all_outcomes = get_individual_outcomes(results; rev = rev)
    outcome_matrix = SortedDict{Int, Vector{Float64}}()
    for outer_id in outer_ids
        tests = zeros(Float64, length(inner_ids))
        for (i, inner_id) in enumerate(inner_ids)
            tests[i] = all_outcomes[outer_id][inner_id]
            #push!(tests, all_outcomes[outer_id][inner_id])
        end
        outcome_matrix[outer_id] = tests
    end
    return outcome_matrix
end

function make_distinction_matrix(outcome_matrix::SortedDict{Int, Vector{Float64}})
    distinction_matrix = SortedDict{Int, Vector{Float64}}()
    for (id, outcomes) in outcome_matrix
        distinctions = Float64[]
        n_outcomes = length(outcomes)
        for i in 1:n_outcomes
            other_start = i + 1
            for j in other_start:n_outcomes
                distinction_score = outcomes[i] != outcomes[j] ? 1.0 : 0.0
                push!(distinctions, distinction_score)
            end
        end
        distinction_matrix[id] = distinctions
    end
    return distinction_matrix
end

function make_distinction_matrix(
    outer_indivs::Vector{<:Individual},
    inner_indivs::Vector{<:Individual},
    results::Vector{<:Result},
)
    outcome_matrix = make_outcome_matrix(outer_indivs, inner_indivs, results)
    distinction_matrix = make_distinction_matrix(outcome_matrix)
    return distinction_matrix
end

function append_outcome_matrix(
    first_matrix::SortedDict{Int, Vector{Float64}}, second_matrix::SortedDict{Int, Vector{Float64}}
)
    if length(first_matrix) != length(second_matrix)
        error("Matrices must have the same number of rows")
    end
    new_matrix = SortedDict{Int, Vector{Float64}}()
    for (id, tests) in first_matrix
        all_tests = vcat(tests, second_matrix[id])
        new_matrix[id] = all_tests
    end
    return new_matrix
end

function make_outcome_and_distinction_matrix(
    outcome_matrix::SortedDict{Int, Vector{Float64}},
)
    distinction_matrix = make_distinction_matrix(outcome_matrix)
    return append_outcome_matrix(outcome_matrix, distinction_matrix)
end

function make_outcome_and_distinction_matrix(
    outer_indivs::Vector{<:Individual},
    inner_indivs::Vector{<:Individual},
    results::Vector{<:Result},
)
    outcome_matrix = make_outcome_matrix(outer_indivs, inner_indivs, results)
    return make_outcome_and_distinction_matrix(outcome_matrix)
end

function implement_competitive_fitness_sharing(outcome_matrix::SortedDict{Int, Vector{Float64}})
    n_outcomes = length(first(outcome_matrix)[2])
    outcome_sums = zeros(Float64, n_outcomes)
    for i in 1:n_outcomes
        for outcomes in values(outcome_matrix)
            outcome_sums[i] += outcomes[i]
        end
    end
    new_outcome_matrix = SortedDict{Int, Vector{Float64}}()

    for (id, outcomes) in outcome_matrix
        new_outcomes = zeros(Float64, n_outcomes)
        for i in 1:n_outcomes
            if outcomes[i] == 1
                new_outcomes[i] = 1 / outcome_sums[i]
            end
        end
        new_outcome_matrix[id] = new_outcomes
    end
    return new_outcome_matrix
end

function condense_outcomes_to_scalar(outcome_matrix::SortedDict{Int, Vector{Float64}})
    new_outcome_matrix = SortedDict{Int, Vector{Float64}}()
    for (id, outcomes) in outcome_matrix
        new_outcome_matrix[id] = [sum(outcomes)]
    end
    return new_outcome_matrix
end

function calculate_fitnesses(individual_tests::SortedDict{Int, Vector{Float64}})
    [sum(tests) for tests in values(individual_tests)]
end

function check_for_nan_in_fitnesses(fitnesses::Vector{Float64})
    if any(isnan, fitnesses)
        throw(ErrorException("NaN in fitnesses"))
    end
end

function get_individuals(v::Vector{<:Record})
    return [v.individual for v in v]
end
