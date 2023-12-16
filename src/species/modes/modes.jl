module Modes

export ModesSpecies, get_individuals, get_persistent_tags, get_children, get_elders
export get_recent, AdaptiveArchive

import ...Individuals: get_individuals
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
        push!(archive, candidate)
    end
    while length(archive) > archive.maximum_length
        # eject the first elements to maintain size
        deleteat!(archive.individuals, 1)
    end
end

function get_recent(archive::AdaptiveArchive, n::Int)
    return archive.individuals[end-n+1:end]
end

struct ModesSpecies{I <: ModesIndividual, I2 <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    previous_population::Vector{I}
    pruned::Vector{I2}
    previous_pruned::Vector{I2}
    all_previous_pruned::Set{I2}
    archive::AdaptiveArchive{I}
end

function get_individuals(species::ModesSpecies)
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