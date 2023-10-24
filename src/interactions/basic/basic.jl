module Basic

export BasicInteraction

import ...Interactions: interact

using ...Phenotypes: Phenotype
using ...MatchMakers: MatchMaker
using ...Observers: Observer, create_observation
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
    observers::Vector{O} = Observer[]
end

all_observe!(environment::Environment, observers::Vector{<:Observer}) = [
   observe!(environment, observer) for observer in observers
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

function interact(
    interaction::BasicInteraction{E, M, O},
    individual_ids::Vector{Int},
    phenotypes::Vector{Phenotype},
) where {E <: EnvironmentCreator, M <: MatchMaker, O <: Observer}
    environment = create_environment(interaction.environment_creator, phenotypes)
    outcome_set = interact(environment, interaction.observers)
    observations = [create_observation(observer) for observer in interaction.observers]
    result = BasicResult(interaction.id, individual_ids, outcome_set, observations)
    return result
end

end