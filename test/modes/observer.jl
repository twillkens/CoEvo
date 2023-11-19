using StatsBase

import CoEvo.Observers: observe!

Base.@kwdef mutable struct FunctionGraphModesObserver <: Observer 
    to_observe::Int = 1
    node_states::Dict{Int, Vector{Float32}} = Dict{Int, Vector{Float32}}()
end

function observe!(
    observer::FunctionGraphModesObserver, phenotype::LinearizedFunctionGraphPhenotype
)
    # Check if this phenotype's id is in the list of ids to observe
        # For each node in the phenotype, append its current value to the appropriate vector
    for node in phenotype.nodes
        # Create a vector for this node's id if not already present
        if !haskey(observer.node_states, node.id)
            observer.node_states[node.id] = Float32[]
        end
        push!(observer.node_states[node.id], node.current_value)
    end
end

function observe!(observer::FunctionGraphModesObserver, environment::FibonacciEnvironment)
    observe!(observer, environment.phenotype)
end

function observe!(observer::FunctionGraphModesObserver, environment::TestBatchEnvironment)
    observe!(observer, environment.phenotype)
end

function observe!(observer::FunctionGraphModesObserver, environment::ContinuousPredictionGameEnvironment)
    if observer.to_observe == 1
        observe!(observer, environment.entity_1)
    elseif observer.to_observe == 2
        observe!(observer, environment.entity_2)
    end
end

struct NodeMetric
    mean::Float32
    median::Float32
end

struct FunctionGraphModesObservation <: Observation
    id::Int
    node_states::Dict{Int, Vector{Float32}}
    node_medians::Dict{Int, Float32}
    node_means::Dict{Int, Float32}
end

function create_observation(observer::FunctionGraphModesObserver)
    node_medians = Dict(id => median(node_states) for (id, node_states) in observer.node_states)
    node_means = Dict(id => mean(node_states) for (id, node_states) in observer.node_states)
    observation = FunctionGraphModesObservation(
        observer.to_observe,
        observer.node_states,
        node_medians,
        node_means
    )
    return observation
end