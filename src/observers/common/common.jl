module Common

export create_observation, create_observations
export NullObservation, NullObserver
export EpisodeLengthObservation, EpisodeLengthObserver

using ...Phenotypes.FunctionGraphs.Linearized: LinearizedFunctionGraphPhenotype
using ..Observers: Observation, Observer, PhenotypeObserver, create_observation

struct NullObservation <: Observation end

struct NullObserver <: Observer end

function create_observations(observers::Vector{<:Observer})
    if length(observers) == 0
        return NullObservation[]
    end
    observations = [create_observation(observer) for observer in observers]
    return observations
end

mutable struct EpisodeLengthObserver <: Observer end

struct EpisodeLengthObservation <: Observation
    episode_length::Int
end


end