
module Distinction

export DistinctionEvaluation, DistinctionEvaluator
export evaluate

import ....Interfaces: evaluate

using Random: AbstractRNG
using DataStructures: SortedDict
using StatsBase: mean
using ....Abstract
using ....Interfaces
using ...Species.Archive: ArchiveSpecies
using ...Clusterers.XMeans: get_derived_tests as get_derived_tests_xmeans
using ...Clusterers.GlobalKMeans: get_derived_tests as get_derived_tests_global_kmeans
using ...Clusterers.NonNegativeMatrixFactorization: get_derived_tests_nmf 

include("distinctions_coarse.jl")

using ...Evaluators.NSGAII: NSGAIIRecord

struct DistinctionEvaluation{R <: Record} <: Evaluation
    id::String
    population_outcome_records::Vector{R}
    population_distinction_records::Vector{R}
    active_archive_distinction_records::Vector{R}
end

Base.@kwdef struct DistinctionEvaluator <: Evaluator 
    maximize::Bool = true
    max_clusters::Int = 5
    clusterer::String = "global_kmeans"
    distance_method::String = "euclidean"
    function_minimums::Union{Vector{Float64}, Nothing} = nothing
    function_maximums::Union{Vector{Float64}, Nothing} = nothing
end

function perform_clustering(
    evaluator::DistinctionEvaluator, 
    tests::SortedDict{Int, Vector{Float64}},
    state::State
)
    if evaluator.clusterer == "xmeans"
        return get_derived_tests_xmeans(
            state.rng, tests, evaluator.max_clusters, evaluator.distance_method
        )
    elseif evaluator.clusterer == "global_kmeans"
        return get_derived_tests_global_kmeans(
            state.rng, tests, evaluator.max_clusters, evaluator.distance_method
        )
    elseif evaluator.clusterer == "nmf"
        return get_derived_tests_nmf(
            state.rng, tests, evaluator.max_clusters
        )
    else
        throw(ErrorException("Unknown clusterer: $(evaluator.clusterer)"))
    end
end

using ...Evaluators.NSGAII: create_records as create_nsgaii_records, nsga_sort!
using ...Criteria: Maximize

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


function create_records(
    evaluator::DistinctionEvaluator, 
    tests::SortedDict{Int, Vector{Float64}}, 
    species::AbstractSpecies,
    method::String,
    state::State, 
)
    if method == "outcomes"
        fitnesses = calculate_fitnesses(tests)
        tests = perform_clustering(evaluator, tests, state)
    elseif method == "distinctions"
        tests = individual_tests_to_individual_distinctions(tests)
        fitnesses = calculate_fitnesses(tests)
        competitive_fitness_sharing!(tests)
    else
        error("Unknown method: $method")
    end
    disco_fitnesses = calculate_fitnesses(tests)
    records = create_nsgaii_records(tests, fitnesses, disco_fitnesses, evaluator, species)
    return records
end

function evaluate(
    evaluator::DistinctionEvaluator,
    species::ArchiveSpecies,
    ecosystem::Ecosystem,
    results::Vector{<:Result},
    state::State
)
    # first we evaluate the population individuals in terms of their outcomes
    # against members of both the other populations and other active archives 
    # using the DISCO algorithm. This will be used for selecting members of the next 
    # generation for the population
    population_outcomes = get_individual_outcomes(results)
    population_outcome_tests = make_individual_tests(species.population, population_outcomes)
    population_outcome_records = create_records(
        evaluator, population_outcome_tests, species, "outcomes", state,
    )
    # TODO: HAck for only two species
    other_species = first(filter(s -> s.id != species.id, ecosystem.all_species))
    # we want to only count the distinctiveness relative to interactions with 
    # members of the learner population of the other species
    to_exclude = Int[individual.id for individual in other_species.active_archive_individuals]
    # we also want to get the results of the active archive individuals against
    # our evaluator. this is the reason for the rev = true argument
    population_distinctions = get_individual_outcomes(results; rev = true, to_exclude = to_exclude)
    population_distinction_tests = make_individual_tests(species.population, population_distinctions)
    population_distinction_records = create_records(
        evaluator, population_distinction_tests, species, "distinctions", state
    )
    active_archive_distinctions = get_individual_outcomes(results; rev = true)
    active_archive_distinction_tests = make_individual_tests(
        species.active_archive_individuals, active_archive_distinctions
    )
    if length(active_archive_distinction_tests) == 0
        R = typeof(first(population_distinction_records))
        active_archive_distinction_records = R[]
    else
        active_archive_distinction_records = create_records(
            evaluator, active_archive_distinction_tests, species, "distinctions", state
        )
    end

    evaluation = DistinctionEvaluation(
        species.id, 
        population_outcome_records, 
        population_distinction_records, 
        active_archive_distinction_records,
    )
    print_records(evaluation)
    #println("rng state after evaluation: ", rng.state)
    return evaluation
end

function print_records(records::Vector{<:NSGAIIRecord})
    for (i, record) in enumerate(records)
        individual = record.individual
        id = individual.id
        #scalar_record = first(filter(r -> r.id == id, evaluation.scalar_fitness_evaluation.records))
        raw_fitness = round(record.fitness, digits = 3)
        fitness = round(record.disco_fitness, digits = 3)
        genotype = round.(individual.genotype.genes; digits = 3)
        rank = record.rank
        crowding = round(record.crowding, digits = 3)
        tests = round.(record.tests; digits = 3)
        println("$i: id = $id, rank = $rank, crowd = $crowding, raw_fit = $raw_fitness, fit = $fitness, tests = $tests, geno = $genotype")#, phenotype = $phenotype")
    end
end


function print_records(evaluation::DistinctionEvaluation)
    println("----------$(evaluation.id)----------")
    println("Population outcome records:")
    print_records(evaluation.population_outcome_records)
    println("Population distinction records:")
    print_records(evaluation.population_distinction_records)
    println("Active archive distinction records:")
    print_records(evaluation.active_archive_distinction_records)
end



end
