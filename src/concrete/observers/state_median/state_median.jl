module StateMedian

export StateMedianObserver, StateMedianObservation

import ....Interfaces: observe!, create_observation
using ....Abstract

using StatsBase: median
using ...Phenotypes.FunctionGraphs: FunctionGraphPhenotype
using StatsBase: median


Base.@kwdef mutable struct StateMedianObserver <: Observer 
    is_active::Bool = false
    all_phenotype_states::Dict{Int, Dict{Int, Vector{Float32}}} = Dict{Int, Dict{Int, Vector{Float32}}}()
    ids_to_observe::Vector{Int} = Int[]
end

Base.@kwdef mutable struct StateMedianObservation <: Observation
    #all_phenotype_state_medians::Dict{Int, Vector{Float32}}
    all_phenotype_states::Dict{Int, Dict{Int, Vector{Float32}}} = Dict{Int, Dict{Int, Vector{Float32}}}()
end

function observe!(
    observer::StateMedianObserver, phenotype::FunctionGraphPhenotype
)
    if phenotype.id in keys(observer.all_phenotype_states)
        for (node, state) in zip(phenotype.nodes, phenotype.current_node_states)
            push!(observer.all_phenotype_states[phenotype.id][node.id], state)
        end
    else
        observer.all_phenotype_states[phenotype.id] = Dict{Int, Vector{Float32}}()
        for (node, state) in zip(phenotype.nodes, phenotype.current_node_states)
            observer.all_phenotype_states[phenotype.id][node.id] = [state]
        end
    end
end

function observe!(observer::StateMedianObserver, environment::Environment)
    if observer.is_active
        if environment.entity_1.id in observer.ids_to_observe
            observe!(observer, environment.entity_1)
        end
        if environment.entity_2.id in observer.ids_to_observe
            observe!(observer, environment.entity_2)
        end
    end
end


function create_observation(observer::StateMedianObserver)
    if !observer.is_active
        return StateMedianObservation()
    else
        return StateMedianObservation(observer.all_phenotype_states)
    end
end

end