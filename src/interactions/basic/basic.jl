module Basic

export BasicInteraction

import ...Interactions: interact
import ...Observers: observe!

using ...Phenotypes: Phenotype
using ...MatchMakers: MatchMaker
using ...Metrics.Common: NullMetric
using ...Observers: Observer, create_observation
using ...Observers.Common: NullObserver, NullObservation, create_observations
using ...Environments: EnvironmentCreator, Environment, create_environment, step!
using ...Environments: get_outcome_set, is_active
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

observe!(observers::Vector{<:Observer}, environment::Environment) = [
   observe!(observer, environment) for observer in observers
]

function interact(environment::Environment, observers::Vector{<:Observer})
    observe!(observers, environment)
    while is_active(environment)
        step!(environment)
        observe!(observers, environment)
    end
    outcome_set = get_outcome_set(environment)
    return outcome_set
end

function interact(environment::Environment, observer::Observer)
    return interact(environment, [observer])
end

function interact(environment::Environment)
    return interact(environment, NullObserver[])
end


function interact(
    interaction::BasicInteraction{E, M, O},
    individual_ids::Vector{Int},
    phenotypes::Vector{Phenotype},
) where {E <: EnvironmentCreator, M <: MatchMaker, O <: Observer}
    environment_creator = interaction.environment_creator
    environment = create_environment(environment_creator, phenotypes...)
    outcome_set = interact(environment, interaction.observers)
    observations = create_observations(interaction.observers)
    result = BasicResult(interaction.id, individual_ids, outcome_set, observations)
    return result
end

end