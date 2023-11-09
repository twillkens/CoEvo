module Common

export create_observation, observe!
export NullObservation, NullObserver
export EpisodeLengthObservation, EpisodeLengthObserver
export FunctionGraphNodeObservation, FunctionGraphNodeObserver

using ...Phenotypes.FunctionGraphs.Linearized
using ..Observers

struct NullObservation <: Observation end

struct NullObserver <: Observer end

mutable struct EpisodeLengthObserver <: Observer end

struct EpisodeLengthObservation <: Observation
    episode_length::Int
end

Base.@kwdef mutable struct FunctionGraphNodeObserver <: PhenotypeObserver 
    to_observe_ids::Vector{Int} = Int[]
    id_node_states = Dict{Int, Dict{Int, Vector{Float32}}}()
end

function observe!(
    observer::FunctionGraphNodeObserver, phenotype::LinearizedFunctionGraphPhenotype
)
    # Check if this phenotype's id is in the list of ids to observe
    if phenotype.id in observer.to_observe_ids
        # Create a dictionary for this phenotype id if not already present
        if !haskey(observer.id_node_states, phenotype.id)
            observer.id_node_states[phenotype.id] = Dict{Int, Vector{Float32}}()
        end
        
        # For each node in the phenotype, append its current value to the appropriate vector
        for node in phenotype.nodes
            # Create a vector for this node's id if not already present
            if !haskey(observer.id_node_states[phenotype.id], node.id)
                observer.id_node_states[phenotype.id][node.id] = Vector{Float32}()
            end
            push!(observer.id_node_states[phenotype.id][node.id], node.current_value)
        end
    end
end


struct FunctionGraphNodeObservation <: Observation
    id_node_states::Dict{Int, Dict{Int, Vector{Float32}}}()
end

function create_observation(observer::FunctionGraphNodeObserver)
    observation = FunctionGraphNodeObservation(observer.id_node_states)
    return observation
end

end