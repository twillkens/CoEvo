module Disco

export DiscoEvaluator, DiscoEvaluation, DiscoRecord, NSGA, nsga!, Max, Min
export dominates, fast_non_dominated_sort!, crowding_distance_assignment!

using DataStructures: OrderedDict, SortedDict
using ....Species.Abstract: AbstractSpecies
using ....Species.Individuals: Individual
using ...Evaluators.Abstract: Evaluation, Evaluator

import ...Evaluators.Interfaces: create_evaluation, get_ranked_ids
using PyCall

include("nsga.jl")
using .NSGA: NSGA, DiscoRecord, nsga!, Max, Min, dominates
using .NSGA: fast_non_dominated_sort!, crowding_distance_assignment!

const center_initializer = PyNULL()
const kmeans = PyNULL()
const xmeans = PyNULL()

function __init__()
    mod = "pyclustering.cluster.center_initializer"
    copy!(center_initializer, pyimport_conda(mod, "pyclustering", "conda-forge"))
    mod = "pyclustering.cluster.kmeans"
    copy!(kmeans, pyimport_conda(mod, "pyclustering", "conda-forge"))
    mod = "pyclustering.cluster.xmeans"
    copy!(xmeans, pyimport_conda(mod, "pyclustering", "conda-forge"))
end


"""
    DiscoRecordCfg <: EvaluationCreator

A configuration for the Disco evaluation. This serves as a placeholder for potential configuration parameters.
"""
Base.@kwdef struct DiscoEvaluator <: Evaluator end

struct DiscoEvaluation <: Evaluation
    species_id::String
    disco_records::Vector{DiscoRecord}
    outcomes::Dict{Int, Dict{Int, Float64}}
end
"""
    DiscoRecord

Represents a Disco evaluation which includes fitness, rank, crowding distance, 
dominance count, list of dominated evaluations, and derived tests.

# Fields
- `fitness::Float64`: The fitness score.
- `rank::Int`: Rank of the individual based on non-dominated sorting.
- `crowding::Float64`: Crowding distance in the objective space.
- `dom_count::Int`: Number of solutions that dominate this individual.
- `dom_list::Vector{Int}`: List of solutions dominated by this individual.
- `derived_tests::Vector{Float64}`: Derived test results.
"""

function vecvec_to_matrix(vecvec)
     dim1 = length(vecvec)
     dim2 = length(vecvec[1])
     my_array = zeros(Float32, dim1, dim2)
     for i in 1:dim1
         for j in 1:dim2
             my_array[i,j] = vecvec[i][j]
         end
     end
     return my_array
 end

function set_derived_tests!(pop::Vector{DiscoRecord}, seed::UInt32)
    ys = [indiv.tests for indiv in pop]
    m = vecvec_to_matrix(ys)
    m = transpose(m)
    centers = center_initializer.kmeans_plusplus_initializer(m, 2, random_state=seed).initialize()
    xmeans_instance = xmeans.xmeans(m, centers, div(length(pop), 2), random_state=seed)
    xmeans_instance.process()
    centers = xmeans_instance.get_centers()
    centers = transpose(centers)
    for (indiv, center) in zip(pop, eachrow(centers))
        indiv.derived_tests = center
    end
end

function create_evaluation(
    ::DiscoEvaluator,
    species::AbstractSpecies,
    outcomes::Dict{Int, Dict{Int, Float64}}
)
    discos = [
        DiscoRecord(
            id = indiv.id, 
            fitness = sum(values(outcomes[indiv.id])), 
            tests = collect(values(SortedDict(collect(outcomes[indiv.id]))))
        ) 
        for indiv in values(merge(species.pop, species.children))
    ]
    set_derived_tests!(discos, UInt32(42))
    sorted_records = nsga!(discos, Max())
    evaluation = DiscoEvaluation(species.id, sorted_records, outcomes)

    return evaluation
end

function get_ranked_ids(evaluation::DiscoEvaluation, ids::Vector{Int})
    ranked_ids = [record.id for record in evaluation.disco_records if record.id in ids]
    return ranked_ids
end

end