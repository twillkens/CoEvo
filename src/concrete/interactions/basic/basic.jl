module Basic

export BasicInteraction

import ....Interfaces: interact, observe!
using ....Abstract
using ....Interfaces

using ...Observers.Null: NullObserver, NullObservation
using ...Results.Basic: BasicResult

Base.@kwdef struct BasicInteraction{E <: EnvironmentCreator, O <: Observer, } <: Interaction
    id::String
    environment_creator::E
    species_ids::Vector{String}
    observer::O = NullObserver()
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

function reset_phenotypes!(phenotypes::Vector{<:Phenotype})
    for phenotype in phenotypes
        reset!(phenotype)
    end
end

function interact(
    interaction::BasicInteraction{E, O},
    individual_ids::Vector{Int},
    phenotypes::Vector{Phenotype},
) where {E <: EnvironmentCreator, O <: Observer}
    reset_phenotypes!(phenotypes)
    environment_creator = interaction.environment_creator
    environment = create_environment(environment_creator, phenotypes...)
    try 
        outcome_set = interact(environment, interaction.observer)
        observations = create_observation(interaction.observer)
        result = BasicResult(interaction.id, individual_ids, outcome_set, observations)
        reset_phenotypes!(phenotypes)
        return result
    catch
        println("environment = $environment")
        println("phenotypes = $phenotypes")
        throw(ErrorException("Error in interact"))
    end
end

end