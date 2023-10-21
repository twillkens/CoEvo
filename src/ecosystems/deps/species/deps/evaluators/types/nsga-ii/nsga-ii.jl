module NSGAII

export NSGAIIEvaluator, NSGAIIEvaluation, NSGAIIMethods, NSGAIIRecord, FastGlobalKMeans

using Random: AbstractRNG
using DataStructures: SortedDict
using ....Species.Abstract: AbstractSpecies
using ....Species.Individuals: Individual
using ...Evaluators.Abstract: Evaluation, Evaluator
import ...Evaluators.Interfaces: create_evaluation

include("fast_global_kmeans.jl")
using .FastGlobalKMeans: FastGlobalKMeans, get_derived_tests

include("methods.jl")
using .NSGAIIMethods: NSGAIIMethods, NSGAIIRecord, nsga_sort!, Max, Min, dominates
using .NSGAIIMethods: fast_non_dominated_sort!, crowding_distance_assignment!

"""
    DiscoRecordCfg <: EvaluationCreator

A configuration for the Disco evaluation. This serves as a placeholder for potential configuration parameters.
"""
Base.@kwdef struct NSGAIIEvaluator <: Evaluator 
    maximize::Bool = true
    perform_disco::Bool = true
    max_clusters::Int = -1
    function_minimums::Union{Vector{Float64}, Nothing} = nothing
    function_maximums::Union{Vector{Float64}, Nothing} = nothing
end

struct NSGAIIEvaluation <: Evaluation
    species_id::String
    records::Vector{NSGAIIRecord}
end

function create_evaluation(
    evaluator::NSGAIIEvaluator,
    rng::AbstractRNG,
    species::AbstractSpecies,
    outcomes::Dict{Int, SortedDict{Int, Float64}}
)
    individuals = [species.population ; species.children]
    filter!(individual -> individual.id in keys(outcomes), individuals)
    ids = [individual.id for individual in individuals]
    individual_tests = SortedDict{Int, Vector{Float64}}(
        id => [pair.second for pair in outcomes[id]]
        for id in ids
    )
    fitnesses = [sum(tests) / length(tests) for tests in values(individual_tests)]
    if any(isnan, fitnesses)
        throw(ErrorException("NaN in fitnesses"))
    end

    if evaluator.perform_disco
        individual_tests = get_derived_tests(rng, individual_tests, evaluator.max_clusters)
    end

    disco_fitnesses = [sum(tests) / length(tests) for tests in values(individual_tests)]
    if any(isnan, disco_fitnesses)
        throw(ErrorException("NaN in disco fitnesses"))
    end

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

    sense = evaluator.maximize ? Max() : Min()
    sorted_records = nsga_sort!(
        records, sense, evaluator.function_minimums, evaluator.function_maximums
    )
    evaluation = NSGAIIEvaluation(species.id, sorted_records)

    return evaluation
end


end