module Basic

export BasicInteraction

import ...Interactions: interact

using ...Phenotypes: Phenotype
using ...MatchMakers: MatchMaker
using ...Metrics.Common: NullMetric
using ...Observers: Observer, create_observation
using ...Observers.Null: NullObserver, NullObservation
using ...Environments: EnvironmentCreator, Environment, create_environment, step!
using ...Environments: get_outcome_set, is_active, observe!
using ...Results.Basic: BasicResult
using ..Interactions: Interaction

Base.@kwdef struct BasicInteraction{
    E <: EnvironmentCreator, 
    M <: MatchMaker, 
    O <: Observer, 
} <: Interaction
    id::String
    environment_creator::E
    species_ids::Vector{String}
    matchmaker::M
    observers::Vector{O} = NullObserver[]
end

all_observe!(environment::Environment, observers::Vector{<:Observer}) = [
   observe!(observer, environment) for observer in observers
]

function interact(environment::Environment, observers::Vector{<:Observer})
    all_observe!(environment, observers)
    while is_active(environment)
        step!(environment)
        all_observe!(environment, observers)
    end
    outcome_set = get_outcome_set(environment)
    return outcome_set
end

function create_observations(observers::Vector{<:Observer})
    if length(observers) == 0
        return NullObservation{NullMetric, Nothing}[]
    end
    observations = [create_observation(observer) for observer in observers]
    return observations
end

function interact(
    interaction::BasicInteraction{E, M, O},
    individual_ids::Vector{Int},
    phenotypes::Vector{Phenotype},
) where {E <: EnvironmentCreator, M <: MatchMaker, O <: Observer}
    environment = create_environment(interaction.environment_creator, phenotypes)
    outcome_set = interact(environment, interaction.observers)
    observations = create_observations(interaction.observers)
    result = BasicResult(interaction.id, individual_ids, outcome_set, observations)
    return result
end

end