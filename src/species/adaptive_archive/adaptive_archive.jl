module AdaptiveArchive

export AdaptiveArchiveSpecies, get_individuals, add_individuals_to_archive!

import ...Individuals: get_individuals

using ...Genotypes: get_size
using Random: AbstractRNG
using StatsBase: sample, mean
using ...Individuals: Individual
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual
using ...Species: AbstractSpecies
using ...Species.Basic: BasicSpecies

struct AdaptiveArchiveSpecies{S <: BasicSpecies, I <: Individual} <: AbstractSpecies
    id::String
    max_archive_size::Int
    n_sample::Int
    basic_species::S
    archive::Vector{I}
    active_ids::Vector{Int}
end

function get_individuals(species::AdaptiveArchiveSpecies)
    basic_individuals = get_individuals(species.basic_species)
    archive_individuals = species.archive
    individuals = [basic_individuals ; archive_individuals]
    return individuals
end


function add_individuals_to_archive!(
    ::AbstractRNG, species::AdaptiveArchiveSpecies, individuals::Vector{<:BasicIndividual}
)
    append!(species.archive, individuals)
    sort!(species.archive, by = individual -> get_size(individual.genotype))
    if length(species.archive) > species.max_archive_size
        # eject the first elements to maintain size
        deleteat!(species.archive, 1:length(species.archive) - species.max_archive_size)
    end
    archive_size = mean([get_size(individual.genotype) for individual in species.archive])
    println(
        "archive_length: ", length(species.archive), 
        ", archive_size: ", round(archive_size, digits=2))
    return species
end
    #if length(species.archive) > species.max_archive_size
    #    # just trim the first ones
    #    all_ids = [individual.id for individual in species.archive]
    #    ids_to_remove = sample(
    #        rng, 
    #        all_ids,
    #        length(species.archive) - species.max_archive_size, 
    #        replace=false
    #    )
    #    filter!(individual -> individual.id ∉ ids_to_remove, species.archive)
    #end

function add_individuals_to_archive!(
    rng::AbstractRNG, species::AdaptiveArchiveSpecies, individuals::Vector{<:ModesIndividual}
)
    individuals = [
        BasicIndividual(individual.id, individual.genotype, Int[]) 
        for individual in individuals
    ]

    add_individuals_to_archive!(rng, species, individuals)
end

end