
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
    raw_tests::SortedDict{Int, Vector{Float64}}, 
    species::AbstractSpecies,
    method::String,
    state::State, 
)
    fitnesses = calculate_fitnesses(raw_tests)
    if method == "cluster"
        tests = perform_clustering(evaluator, raw_tests, state)
    elseif method == "fitness_sharing"
        tests = implement_competitive_fitness_sharing(raw_tests)
        tests = condense_outcomes_to_scalar(tests)
    elseif method == "scalar"
        tests = condense_outcomes_to_scalar(raw_tests)
    else
        error("Unknown method: $method")
    end
    disco_fitnesses = calculate_fitnesses(tests)
    records = create_nsgaii_records(raw_tests, tests, fitnesses, disco_fitnesses, evaluator, species)
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
    other_species = first(filter(s -> s.id != species.id, ecosystem.all_species))
    if species.id == "A"
        #others = [other_species.population ; other_species.active_archive_individuals]
        others = other_species.population
        #println("n_others = $(length(others))")

        population_outcome_matrix = make_outcome_matrix(
            species.population, others, results
        )
        population_outcome_records = create_records(
            evaluator, population_outcome_matrix, species, "cluster", state,
        )
    elseif species.id == "B"
        others = other_species.population
        population_outcome_matrix = make_distinction_matrix(
        #population_outcome_matrix = make_outcome_matrix(
            species.population, others, results
        )
        population_outcome_records = create_records(
            evaluator, population_outcome_matrix, species, "fitness_sharing", state,
        )
    else
        error("Unknown species: $(species.id)")
    end
    R = typeof(first(population_outcome_records))
    population_distinction_records = R[]
    active_archive_distinction_records = R[]

    evaluation = DistinctionEvaluation(
        species.id, 
        population_outcome_records, 
        population_distinction_records, 
        active_archive_distinction_records,
    )
    print_records(evaluation)
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
        # get the index of the maximum value in tests
        max_index = argmax(individual.genotype.genes)
        println("$i: r = $rank, crwd = $crowding, f = $raw_fitness, f_a = $fitness, t = $tests, g = $genotype, m_i = $max_index")#, phenotype = $phenotype")
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