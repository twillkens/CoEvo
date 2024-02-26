module DodoLearner

export DodoLearnerSpeciesCreator, create_species, update_species!, create_children

import ....Interfaces: get_individuals, create_species, update_species!

using Random: AbstractRNG
using ....Abstract
using ....Interfaces
using ...Individuals.Dodo: DodoIndividual
using Random
using StatsBase

Base.@kwdef mutable struct DodoLearnerSpecies{I <: DodoIndividual} <: AbstractSpecies
    id::String
    population::Vector{I}
    parents::Vector{I}
    children::Vector{I}
end

function get_all_individuals(species::DodoLearnerSpecies)
    return species.population
end

function Base.getindex(species::DodoLearnerSpecies, i::Int)
    index = findfirst(individual -> individual.id == i, species.population)
    if index === nothing
        error("individual with id = $i not found")
    end
    return species.population[index]
end


Base.@kwdef struct DodoLearnerSpeciesCreator <: SpeciesCreator
    id::String
    n_parents::Int
    temperature_increment_frequency::Int = 10
    maximum_temperature::Int = 20
end

function create_children(
    species_creator::DodoLearnerSpeciesCreator, 
    parents::Vector{I}, 
    reproducer::Reproducer, 
    state::State
) where I <: DodoIndividual
    all_parents = Vector{Vector{I}}()
    for _ in 1:species_creator.n_parents
        parents = sample(state.rng, parents, 2, replace=false)
        push!(all_parents, parents)
    end
    children = recombine(reproducer.recombiner, reproducer.mutator, all_parents, state)
    return children
end

function create_species(
    species_creator::DodoLearnerSpeciesCreator, reproducer::Reproducer, state::State
)
    parents = create_individuals(
        reproducer.individual_creator, species_creator.n_parents, reproducer, state
    )
    children = create_children(species_creator, parents, reproducer, state)
    population = [parents ; children]
    species = DodoLearnerSpecies(species_creator.id, population, parents, children)
    return species
end

function validate_species(
    species::DodoLearnerSpecies, species_creator::DodoLearnerSpeciesCreator
)
    n_population_expected = species_creator.n_parents * 2
    if length(species.parents) != species_creator.n_parents
        error("parents length = $(length(species.parents)), expected = $(species_creator.n_parents)")
    end
    if length(species.children) != species_creator.n_parents
        error("children length = $(length(species.children)), expected = $(species_creator.n_parents)")
    end
    if length(species.population) != n_population_expected
        error("population length = $(length(species.population)), expected = $n_population_expected")
    end
    all_ids = [individual.id for individual in species.population]
    if length(unique(all_ids)) != n_population_expected
        error("population contains duplicate ids")
    end
end

using ...Evaluators.DodoLearner: DodoLearnerEvaluation

function get_new_parents(species::DodoLearnerSpecies, evaluation::DodoLearnerEvaluation)
    filtered_parents = [
        individual for individual in species.parents 
            if !(individual.id in evaluation.parents_to_retire)
    ]
    promoted_children = [
        individual for individual in species.children 
            if individual.id in evaluation.children_to_promote
    ]
    new_parents = [filtered_parents ; promoted_children]
    return new_parents
end

function age_parents!(species::DodoLearnerSpecies)
    for individual in species.parents
        individual.age += 1
    end
end

function increase_parent_temperature!(
    species::DodoLearnerSpecies, 
    species_creator::DodoLearnerSpeciesCreator
)
    for individual in species.parents
        is_max_temp = individual.temperature >= species_creator.maximum_temperature
        is_time_to_increase = individual.age % species_creator.temperature_increment_frequency == 0
        if individual.age > 1 && !is_max_temp && is_time_to_increase
            individual.temperature += 1
        end
    end
end

function update_species!(
    species::DodoLearnerSpecies, 
    species_creator::DodoLearnerSpeciesCreator,
    evaluation::DodoLearnerEvaluation,
    reproducer::Reproducer,
    state::State
) 
    species.parents = get_new_parents(species, evaluation)
    species.children = create_children(species_creator, species.parents, reproducer, state)
    species.population = [species.parents ; species.children]
    age_parents!(species)
    increase_parent_temperature!(species, species_creator)
    validate_species(species, species_creator)
end

end
