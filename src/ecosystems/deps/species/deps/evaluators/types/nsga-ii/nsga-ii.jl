module NSGAII

export NSGAIIEvaluator, NSGAIIEvaluation, NSGAIIMethods, NSGAIIRecord, FastGlobalKMeans

using Random: AbstractRNG
using DataStructures: SortedDict
using ....Species.Abstract: AbstractSpecies
using ....Species.Individuals: Individual
using ...Evaluators.Abstract: Evaluation, Evaluator

import ...Evaluators.Interfaces: create_evaluation, get_ranked_ids

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
    include_parents::Bool = false
end

struct NSGAIIEvaluation <: Evaluation
    species_id::String
    disco_records::Vector{NSGAIIRecord}
    outcomes::Dict{Int, Dict{Int, Float64}}
end


function create_evaluation(
    evaluator::NSGAIIEvaluator,
    rng::AbstractRNG,
    outcomes::Dict{Int, Dict{Int, Float64}},
    ids::Vector{Int},
    species_id::String = "default"
)
    # println("create_evaluation")
    # println("ids: ", ids)
    # println(keys(outcomes))
    individual_tests = SortedDict{Int, Vector{Float64}}(
        id => [pair.second for pair in sort(collect(outcomes[id]), by = x -> x[1])]
        for id in ids
    )
    if evaluator.perform_disco
        individual_tests = get_derived_tests(rng, individual_tests, evaluator.max_clusters)
    end

    records = [
        NSGAIIRecord(id = id, fitness = sum(tests) / length(tests), tests = tests)
        for (id, tests) in individual_tests
    ]
    sense = evaluator.maximize ? Max() : Min()
    sorted_records = nsga_sort!(
        records, sense, evaluator.function_minimums, evaluator.function_maximums
    )
    evaluation = NSGAIIEvaluation(species_id, sorted_records, outcomes)

    return evaluation
end

function create_evaluation(
    evaluator::NSGAIIEvaluator,
    rng::AbstractRNG,
    species::AbstractSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}}
)
    ids = evaluator.include_parents ? 
        collect(keys(merge(species.pop, species.children))) : collect(keys(species.children))
    evaluation = create_evaluation(evaluator, rng, outcomes, ids, species.id)
    return evaluation
end

function get_ranked_ids(evaluation::NSGAIIEvaluation, ids::Vector{Int})
    ranked_ids = [record.id for record in evaluation.disco_records if record.id in ids]
    return ranked_ids
end

end