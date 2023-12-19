module Modes

export ModesSpecies, get_individuals, get_persistent_tags, get_children, get_elders
export ModesSpecies, get_individuals_to_evaluate, add_to_archive!, get_recent

import ...Individuals: get_individuals
import ...Species: get_individuals_to_evaluate, get_individuals_to_perform
import Base: length

using ...Genotypes: get_size
using Random: AbstractRNG
using StatsBase: sample, mean, Weights
using ...Individuals: Individual
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual
using ...Species: AbstractSpecies

struct ModesArchive{I <: Individual}
    maximum_length::Int
    individuals::Vector{I}
end

function length(archive::ModesArchive)
    return length(archive.individuals)
end

function add_to_archive!(archive::ModesArchive, candidates::Vector{<:Individual})
    length_before = length(archive)
    for candidate in candidates
        if candidate.id in Set([individual.id for individual in archive.individuals])
            filter!(individual -> individual.id != candidate.id, archive.individuals)
        end
        push!(archive.individuals, candidate)
    end
    while length(archive) > archive.maximum_length
        # eject the first elements to maintain size
        deleteat!(archive.individuals, 1)
    end
    length_after = length(archive)
    if length_before == archive.maximum_length && length_after < archive.maximum_length
        println("archive length decreased from $length_before to $length_after")
        println("archive ids = $([individual.id for individual in archive.individuals])")
        println("candidates ids = $([individual.id for individual in candidates])")
        throw(ErrorException("archive length decreased"))
    end
end

function get_recent(archive::ModesArchive, n::Int)
    return archive.individuals[end-n+1:end]
end


Base.@kwdef struct ModesSpecies{I <: ModesIndividual} <: AbstractSpecies
    id::String
    population::Vector{I}
    previous_population::Vector{I}
    pruned::Vector{I}
    previous_pruned::Vector{I}
    all_previous_pruned::Set{I}
    adaptive_archive::ModesArchive{I}
    elites_archive::ModesArchive{I}
    previous_adaptive::Vector{I}
    previous_elites::Vector{I}
end

function ModesSpecies(
    id::String, population::Vector{I}, adaptive_archive_length::Int, elites_archive_length::Int
) where {I <: ModesIndividual}
    previous_population = copy(population)
    pruned = I[]
    previous_pruned = I[]
    all_previous_pruned = Set{I}()
    species = ModesSpecies(
        id = id, 
        population = population, 
        previous_population = previous_population, 
        pruned = pruned, 
        previous_pruned = previous_pruned, 
        all_previous_pruned = all_previous_pruned,
        adaptive_archive = ModesArchive{I}(adaptive_archive_length, I[]),
        elites_archive = ModesArchive{I}(elites_archive_length, I[]),
        previous_adaptive = I[],
        previous_elites = I[],
    )
    return species
end

function get_individuals(species::ModesSpecies)
    return species.population
end

function get_individuals_to_evaluate(species::ModesSpecies)
    return species.population
end

function get_individuals_to_perform(species::ModesSpecies,)
    return [species.population ; species.adaptive_archive.individuals ; species.elites_archive.individuals]
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