module StateMedian

export StateMedianObserver, StateMedianObservation

import ....Interfaces: observe!, create_observation
using ....Abstract

using StatsBase: median
using ...Phenotypes.FunctionGraphs: FunctionGraphPhenotype
using StatsBase: median


Base.@kwdef mutable struct StateMedianObserver <: Observer 
    is_active::Bool = false
    all_phenotype_states::Dict{Int, Vector{Vector{Float32}}} = Dict{Int, Vector{Vector{Float32}}}()
end

Base.@kwdef mutable struct StateMedianObservation <: Observation
    all_phenotype_state_medians::Dict{Int, Vector{Float32}}
end

function observe!(
    observer::StateMedianObserver, phenotype::FunctionGraphPhenotype
)
    if phenotype.id in keys(observer.all_phenotype_states)
        push!(observer.all_phenotype_states[phenotype.id], phenotype.current_node_states)
    else
        observer.all_phenotype_states[phenotype.id] = [phenotype.current_node_states]
    end
end

function observe!(observer::StateMedianObserver, environment::Environment)
    if observer.is_active
        observe!(observer, environment.entity_1)
        observe!(observer, environment.entity_2)
    end
end

function safe_median(values::Vector{Float32})
    median_value = median(values)
    if isinf(median_value)
        median_value = median_value > 0 ? prevfloat(Inf32) : nextfloat(-Inf32)
    elseif isnan(median_value)
        error("NaN median value")
    end
    return median_value
end

function create_observation(observer::StateMedianObserver)
    if !observer.is_active
        return StateMedianObservation(Dict{Int, Vector{Float32}}())
    end
    all_phenotype_state_medians = Dict{Int, Vector{Float32}}()
    for (id, phenotype_states) in observer.all_phenotype_states
        num_states = length(phenotype_states)
        if num_states > 0
            state_length = length(first(phenotype_states))
            phenotype_state_medians = Vector{Float32}(undef, state_length)
            for i in 1:state_length
                state_values_at_i = [state[i] for state in phenotype_states]
                phenotype_state_medians[i] = safe_median(state_values_at_i)
            end
            
            all_phenotype_state_medians[id] = phenotype_state_medians
        end
    end
    observation = StateMedianObservation(all_phenotype_state_medians)
    return observation
end


end