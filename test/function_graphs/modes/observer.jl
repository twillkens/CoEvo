
import CoEvo.Observers: observe!, create_observation

Base.@kwdef mutable struct FunctionGraphModesObserver <: Observer 
    to_observe_id::Int = 0
    other_id::Int = 0
    node_states::Dict{Int, Vector{Float32}} = Dict{Int, Vector{Float32}}()
end

function observe!(
    observer::FunctionGraphModesObserver, phenotype::LinearizedFunctionGraphPhenotype
)
        # For each node in the phenotype, append its current value to the appropriate vector
    # if phenotype.id == -12609
    #     println(phenotype)
    # end
    for node in phenotype.nodes
        # Create a vector for this node's id if not already present
        if !haskey(observer.node_states, node.id)
            observer.node_states[node.id] = Float32[]
        end
        push!(observer.node_states[node.id], node.current_value)
    end
end

function observe!(
    observer::FunctionGraphModesObserver, environment::ContinuousPredictionGameEnvironment
)
    if environment.entity_1.id < 0
        observer.to_observe_id = environment.entity_1.id
        observer.other_id = environment.entity_2.id
        observe!(observer, environment.entity_1)
    elseif environment.entity_2.id < 0
        observer.to_observe_id = environment.entity_2.id
        observer.other_id = environment.entity_1.id
        observe!(observer, environment.entity_2)
    else
        throw(ErrorException("Neither entity has a negative id for FunctionGraphModesObserver."))
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
        id => median(all_gene_output_dict[id]) for id in keys(all_gene_output_dict)
    )
    return gene_median_dict
end

import CoEvo.Results: get_observations

function get_observations(observations::Vector{<:Observation}, id::Int)
    observations = filter(observation -> observation.id == id, observations)
    return observations
end