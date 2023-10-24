module Basic

export BasicInteraction

using ....Species.Phenotypes.Abstract: Phenotype
using ...Interactions.Abstract: Interaction
using ...MatchMakers.Abstract: MatchMaker
using ...Observers.Abstract: Observer
#using ...Observers.Concrete.Null: NullObserver
using ...Environments.Abstract: EnvironmentCreator, Environment
using ...Results: Result

using ...Observers.Interfaces: create_observation
using ...Environments.Interfaces: create_environment, next!
using ...Environments.Interfaces: get_outcome_set, is_active, observe!

import ...Interactions.Interfaces: interact

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
        next!(environment)
        all_observe!(environment, observers)
    end
    outcome_set = get_outcome_set(environment)
    return outcome_set
end

function interact(
    interaction::BasicInteraction{E, M, O},
    indiv_ids::Vector{Int},
    phenotypes::Vector{Phenotype},
) where {E <: EnvironmentCreator, M <: MatchMaker, O <: Observer}
    environment = create_environment(interaction.environment_creator, phenotypes)
    outcome_set = interact(environment, interaction.observers)
    observations = [create_observation(observer) for observer in interaction.observers]
    result = Result(interaction.id, indiv_ids, outcome_set, observations)
    return result
end

end