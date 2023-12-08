module Modes

export PhenotypeStateObserver, PhenotypeStateObservation

import CoEvo.Observers: observe!, create_observation

using StatsBase: median
using ..Observers: Observer, Observation
using ...Phenotypes.FunctionGraphs.Linearized: LinearizedFunctionGraphPhenotype
using ...Phenotypes: PhenotypeState, get_phenotype_state

abstract type ModesObserver <: Observer end

abstract type ModesObservation <: Observation end

Base.@kwdef mutable struct PhenotypeStateObserver{T <: PhenotypeState} <: Observer 
    to_observe_id::Int = 0
    other_id::Int = 0
    states::Vector{T} = T[]
end

function observe!(
    observer::PhenotypeStateObserver, phenotype::LinearizedFunctionGraphPhenotype
)
    state = get_phenotype_state(phenotype)
    push!(observer.states, state)
end

struct PhenotypeStateObservation{T <: PhenotypeState} <: Observation
    id::Int
    other_id::Int
    states::Vector{T}
end

function create_observation(observer::PhenotypeStateObserver{T}) where T <: PhenotypeState
    observation = FunctionGraphModesObservation(
        observer.to_observe_id,
        observer.other_id,
        observer.states
    )
    observer.to_observe_id = 0
    observer.other_id = 0
    empty!(observer.states)
    return observation
end

Base.@kwdef mutable struct FunctionGraphModesObserver <: ModesObserver 
    to_observe_id::Int = 0
    other_id::Int = 0
    node_states::Dict{Int, Vector{Float32}} = Dict{Int, Vector{Float32}}()
end

function observe!(
    observer::FunctionGraphModesObserver, phenotype::LinearizedFunctionGraphPhenotype
)
    for node in phenotype.nodes
        if !haskey(observer.node_states, node.id)
            observer.node_states[node.id] = Float32[]
        end
        push!(observer.node_states[node.id], node.current_value)
    end
end

struct FunctionGraphModesObservation <: Observation
    id::Int
    other_id::Int
    node_states::Dict{Int, Vector{Float32}}
end

function create_observation(observer::FunctionGraphModesObserver)
    observation = FunctionGraphModesObservation(
        observer.to_observe_id,
        observer.other_id,
        observer.node_states
    )
    observer.to_observe_id = 0
    observer.other_id = 0
    observer.node_states = Dict{Int, Vector{Float32}}()
    return observation
end

safe_median(x::R) where R <: Real = isinf(x) ? zero(R) : median(x)

function get_gene_median_dict(observations::Vector{FunctionGraphModesObservation})
    all_gene_output_dict = Dict{Int, Vector{Float32}}()
    for observation in observations
        for (id, node_states) in observation.node_states
            if !haskey(all_gene_output_dict, id)
                all_gene_output_dict[id] = Float32[]
            end
            push!(all_gene_output_dict[id], node_states...)
        end
    end
    gene_median_dict = Dict(
        id => safe_median(all_gene_output_dict[id]) for id in keys(all_gene_output_dict)
    )
    return gene_median_dict
end


end