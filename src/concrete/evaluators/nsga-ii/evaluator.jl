export NSGAIIEvaluator, NSGAIIEvaluation
export evaluate, make_individual_tests, calculate_fitnesses, check_for_nan_in_fitnesses
export create_records, evaluate

import ....Interfaces: evaluate
using ....Interfaces
using ....Abstract
using ...Criteria

using ...Clusterers.XMeans: get_derived_tests as get_derived_tests_xmeans
using ...Clusterers.GlobalKMeans: get_derived_tests as get_derived_tests_global_kmeans

Base.@kwdef struct NSGAIIEvaluator <: Evaluator 
    scalar_fitness_evaluator::ScalarFitnessEvaluator = ScalarFitnessEvaluator()
    maximize::Bool = true
    perform_disco::Bool = true
    max_clusters::Int = -1
    clusterer::String = "global_kmeans"
    distance_method::String = "euclidean"
    function_minimums::Union{Vector{Float64}, Nothing} = nothing
    function_maximums::Union{Vector{Float64}, Nothing} = nothing
    evaluation_time::Float64 = 0.0
end

struct NSGAIIEvaluation <: Evaluation
    id::String
    records::Vector{NSGAIIRecord}
    scalar_fitness_evaluation::ScalarFitnessEvaluation
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
    ids = [individual.id for individual in individuals]
    outcomes = convert_to_sorteddict(outcomes)
    individual_tests = SortedDict{Int, Vector{Float64}}(
        id => [pair.second for pair in outcomes[id]]
        for id in ids
    )
    return individual_tests
end

function calculate_fitnesses(individual_tests::SortedDict{Int, Vector{Float64}})
    [sum(tests) / length(tests) for tests in values(individual_tests)]
end

function check_for_nan_in_fitnesses(fitnesses::Vector{Float64})
    if any(isnan, fitnesses)
        throw(ErrorException("NaN in fitnesses"))
    end
end

function create_records(
    individual_tests::SortedDict{Int, Vector{Float64}},
    fitnesses::Vector{Float64},
    disco_fitnesses::Vector{Float64}
)
    records = NSGAIIRecord[]
    for (index, id_tests) in enumerate(individual_tests)
        id, tests = id_tests
        record = NSGAIIRecord(
            id = id, 
            fitness = fitnesses[index], 
            disco_fitness = disco_fitnesses[index],
            tests = tests
        )
        push!(records, record)
    end
    records
end

function evaluate(
    evaluator::NSGAIIEvaluator,
    species::AbstractSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}},
    state::State
)
    
    individuals = get_individuals_to_evaluate(species)
    individual_ids = [individual.id for individual in individuals]
    outcomes = Dict(filter(pair -> first(pair) in individual_ids, collect(outcomes)))
        
    scalar_fitness_evaluation = evaluate(
        evaluator.scalar_fitness_evaluator, species, outcomes, state
    )
    for individual in individuals
        if individual.id ∉ keys(outcomes)
            error("Individual $(individual.id) not in outcomes")
        end
    end
    #filter!(individual -> individual.id in keys(outcomes), individuals)
    
    individual_tests = make_individual_tests(individuals, outcomes)
    #println("individual_tests = $individual_tests")

    fitnesses = calculate_fitnesses(individual_tests)
    check_for_nan_in_fitnesses(fitnesses)
    #println("RNG BEFORE DISCO = $(state.rng.state)")

    if evaluator.clusterer == "xmeans"
        individual_tests = get_derived_tests_xmeans(
            state.rng, individual_tests, evaluator.max_clusters, evaluator.distance_method
        )
    elseif evaluator.clusterer == "global_kmeans"
        individual_tests = get_derived_tests_global_kmeans(
            state.rng, individual_tests, evaluator.max_clusters, evaluator.distance_method
        )
    else
        throw(ErrorException("Unknown clusterer: $(evaluator.clusterer)"))
    end
    #println("RNG AFTER DISCO = $(state.rng.state)")

    disco_fitnesses = calculate_fitnesses(individual_tests)
    check_for_nan_in_fitnesses(disco_fitnesses)

    records = create_records(individual_tests, fitnesses, disco_fitnesses)

    criterion = evaluator.maximize ? Maximize() : Minimize()
    sorted_records = nsga_sort!(
        records, criterion, evaluator.function_minimums, evaluator.function_maximums
    )
    evaluation = NSGAIIEvaluation(species.id, sorted_records, scalar_fitness_evaluation)

    return evaluation
end