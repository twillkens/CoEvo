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

function BasicInteraction(interaction::BasicInteraction, observers::Vector{<:Observer})
    interaction = BasicInteraction(
        interaction.id,
        interaction.environment_creator,
        interaction.species_ids,
        interaction.matchmaker,
        observers,
    )
    return interaction
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

using ...Phenotypes: reset!

function interact(
    interaction::BasicInteraction{E, M, O},
    individual_ids::Vector{Int},
    phenotypes::Vector{Phenotype},
) where {E <: EnvironmentCreator, M <: MatchMaker, O <: Observer}
    [reset!(phenotype) for phenotype in phenotypes]
    environment_creator = interaction.environment_creator
    environment = create_environment(environment_creator, phenotypes...)
    try 
        outcome_set = interact(environment, interaction.observers)
        observations = create_observations(interaction.observers)
        result = BasicResult(interaction.id, individual_ids, outcome_set, observations)
        [reset!(phenotype) for phenotype in phenotypes]
        return result
    catch
        println("environment = $environment")
        println("phenotypes = $phenotypes")
        throw(ErrorException("Error in interact"))
    end
end

end