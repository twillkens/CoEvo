module Basic

export BasicInteraction

import ....Interfaces: interact
using ....Abstract
using ....Interfaces

using ...Observers.Null: NullObserver
using ...Results.Basic: BasicResult

Base.@kwdef struct BasicInteraction{E <: EnvironmentCreator, O <: Observer} <: Interaction
    id::String
    environment_creator::E
    species_ids::Vector{String}
    observer::O = NullObserver()
end

function interact(environment::Environment, observer::Observer)
    observe!(observer, environment)
    while is_active(environment)
        step!(environment)
        observe!(observer, environment)
    end
    outcome_set = get_outcome_set(environment)
    observation = create_observation(observer)
    return outcome_set, observation
end

function reset_phenotypes!(phenotypes::Vector{<:Phenotype})
    for phenotype in phenotypes
        reset!(phenotype)
    end
end

function interact(
    interaction::BasicInteraction{E, O}, match::Match, phenotypes::Vector{<:Phenotype},
) where {E <: EnvironmentCreator, O <: Observer}
    reset_phenotypes!(phenotypes)
    environment_creator = interaction.environment_creator
    environment = create_environment(environment_creator, phenotypes...)
    try 
        outcome_set, observation = interact(environment, interaction.observer)
        result = BasicResult(match, outcome_set, observation)
        reset_phenotypes!(phenotypes)
        return result
    catch e
        println("environment = $environment")
        println("phenotypes = $phenotypes")
        throw(e)
    end
end

end