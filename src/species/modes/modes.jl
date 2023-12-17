module Modes

export ModesSpecies, get_individuals, get_persistent_tags, get_children, get_elders
export get_recent, AdaptiveArchive, add_to_archive!, ModesSpecies, get_individuals_to_evaluate

import ...Individuals: get_individuals
import ...Species: get_individuals_to_evaluate
import Base: length

using ...Genotypes: get_size
using Random: AbstractRNG
using StatsBase: sample, mean, Weights
using ...Individuals: Individual
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual
using ...Species: AbstractSpecies


struct AdaptiveArchive{I <: Individual}
    maximum_length::Int
    individuals::Vector{I}
end

function length(archive::AdaptiveArchive)
    return length(archive.individuals)
end

function add_to_archive!(archive::AdaptiveArchive, candidates::Vector{<:Individual})
    for candidate in candidates
        push!(archive.individuals, candidate)
    end
    while length(archive) > archive.maximum_length
        # eject the first elements to maintain size
        deleteat!(archive.individuals, 1)
    end
end

function get_recent(archive::AdaptiveArchive, n::Int)
    return archive.individuals[end-n+1:end]
end

Base.@kwdef struct ModesSpecies{I <: ModesIndividual} <: AbstractSpecies
    id::String
    population::Vector{I}
    previous_population::Vector{I}
    pruned::Vector{I}
    previous_pruned::Vector{I}
    all_previous_pruned::Set{I}
    archive::AdaptiveArchive{I}
end

function ModesSpecies(
    id::String, population::Vector{I}, max_archive_size::Int
) where {I <: ModesIndividual}
    previous_population = copy(population)
    pruned = I[]
    previous_pruned = I[]
    all_previous_pruned = Set{I}()
    archive = AdaptiveArchive{I}(max_archive_size, I[])
    species = ModesSpecies(
        id, 
        population, 
        previous_population, 
        pruned, 
        previous_pruned, 
        all_previous_pruned,
        archive
    )
    return species
end

function get_individuals(species::ModesSpecies)
    return species.population
end

function get_individuals_to_evaluate(species::ModesSpecies)
    return species.population
end

function get_children(species::ModesSpecies)
    children = [individual for individual in species.population if individual.age == 0]
    return children
end

function get_elders(species::ModesSpecies)
    elders = [individual for individual in species.population if individual.age > 0]
    return elders
end

function get_persistent_tags(species::ModesSpecies)
    persistent_tags = Set([individual.tag for individual in species.population])
    return persistent_tags
end

end