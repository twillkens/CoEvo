export evaluate
export make_individual_tests, calculate_fitnesses, check_for_nan_in_fitnesses
export convert_to_sorteddict
export get_individuals

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