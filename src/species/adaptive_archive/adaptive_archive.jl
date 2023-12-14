module AdaptiveArchive

export AdaptiveArchiveSpecies, get_individuals, add_individuals_to_archive!

import ...Individuals: get_individuals

using ...Genotypes: get_size
using Random: AbstractRNG
using StatsBase: sample, mean, Weights
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

# TODO: add to utils
function sample_proportionate_to_genotype_size(
    rng::AbstractRNG, individuals::Vector{<:Individual}, n_sample::Int; 
    inverse::Bool = false,
    replace::Bool = false
)
    complexity_scores = [get_size(individual.genotype) for individual in individuals]
    complexity_scores = 1 .+ complexity_scores
    complexity_scores = inverse ? 1 ./ complexity_scores : complexity_scores
    weights = Weights(complexity_scores)
    return sample(rng, individuals, weights, n_sample, replace = replace)
end

function add_individuals_to_archive!(
    rng::AbstractRNG, species::AdaptiveArchiveSpecies, candidates::Vector{<:BasicIndividual}
)
    while length(species.archive) > species.max_archive_size
        # eject the first elements to maintain size
        deleteat!(species.archive, 1)
    end
    for candidate in candidates
        push!(species.archive, candidate)
    end

    archive_sizes = [get_size(individual.genotype) for individual in species.archive]
    new_sizes = [get_size(individual.genotype) for individual in candidates]
    archive_size = mean([get_size(individual.genotype) for individual in species.archive])
    println("-------------------------")
    println("archive sizes: $archive_sizes")
    println("new sizes: $new_sizes")
    println(
        "archive_length: ", length(species.archive), 
        ", mean_archive_size: ", round(archive_size, digits=2))
    return species
end

#function add_individuals_to_archive!(
#    rng::AbstractRNG, species::AdaptiveArchiveSpecies, candidates::Vector{<:BasicIndividual}
#)
#    sort!(species.archive, by = individual -> get_size(individual.genotype))
#    new_sizes = [get_size(individual.genotype) for individual in candidates]
#    archive_sizes = [get_size(individual.genotype) for individual in species.archive]
#    println("-------------------------")
#    println("new sizes: $new_sizes")
#    println("archive sizes: $archive_sizes")
#
#    minimum_archive_size = length(archive_sizes) > 0 ? minimum(archive_sizes) : 0
#    for candidate in candidates
#        if get_size(candidate.genotype) >= minimum_archive_size
#            push!(species.archive, candidate)
#        end
#    end
#    sort!(species.archive, by = individual -> get_size(individual.genotype))
#    while length(species.archive) > species.max_archive_size
#        # eject the first elements to maintain size
#        deleteat!(species.archive, 1)
#    end
#    archive_size = mean([get_size(individual.genotype) for individual in species.archive])
#    println(
#        "archive_length: ", length(species.archive), 
#        ", mean_archive_size: ", round(archive_size, digits=2))
#    return species
#end

# function add_individuals_to_archive!(
#     ::AbstractRNG, species::AdaptiveArchiveSpecies, individuals::Vector{<:BasicIndividual}
# )
#     append!(species.archive, individuals)
#     sort!(species.archive, by = individual -> get_size(individual.genotype))
#     if length(species.archive) > species.max_archive_size
#         # eject the first elements to maintain size
#         deleteat!(species.archive, 1:length(species.archive) - species.max_archive_size)
#     end
#     archive_size = mean([get_size(individual.genotype) for individual in species.archive])
#     println(
#         "archive_length: ", length(species.archive), 
#         ", archive_size: ", round(archive_size, digits=2))
#     return species
# end
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