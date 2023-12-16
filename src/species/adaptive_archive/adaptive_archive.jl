module AdaptiveArchive

export AdaptiveArchiveSpecies, get_individuals, add_individuals_to_archive!, add_elites!
export add_modes_elite_to_archive!

import ...Individuals: get_individuals

using ...Genotypes: get_size
using Random: AbstractRNG
using StatsBase: sample, mean, Weights
using ...Individuals: Individual
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: PruneIndividual
using ...Species: AbstractSpecies
using ...Species.Basic: BasicSpecies

Base.@kwdef struct AdaptiveArchiveSpecies{S <: BasicSpecies, I <: Individual} <: AbstractSpecies
    id::String
    max_archive_size::Int
    basic_species::S
    archive::Vector{I}
    n_sample::Int
    active_ids::Vector{Int}
    elites::Vector{I}
    n_sample_elites::Int
    active_elite_ids::Vector{Int}
    fitnesses::Dict{Int, Float64}
    modes_elites::Vector{I}
end

function get_individuals(species::AdaptiveArchiveSpecies)
    basic_individuals = get_individuals(species.basic_species)
    archive_individuals = species.archive
    individuals = [basic_individuals ; archive_individuals; species.elites]
    return individuals
end

function add_individuals_to_archive!(
    ::AbstractRNG, species::AdaptiveArchiveSpecies, candidates::Vector{<:BasicIndividual}
)
    for candidate in candidates
        push!(species.archive, candidate)
    end
    while length(species.archive) > species.max_archive_size
        # eject the first elements to maintain size
        deleteat!(species.archive, 1)
    end

    ids = [individual.id for individual in species.archive]
    new_sizes = [get_size(individual.genotype) for individual in candidates]
    fitnesses = [round(species.fitnesses[individual.id], digits = 3) for individual in candidates]
    incoming = collect(zip(ids, new_sizes, fitnesses))
    archive_size = mean([get_size(individual.genotype) for individual in species.archive])
    active_ids = species.active_ids
    previous_elite_size = length(species.elites) == 0 ? 0 : get_size(last(species.elites).genotype)
    println("-------------------------")
    #println("archive sizes: $archive_sizes")
    println("incoming adaptive: $incoming")
    println("ids: ", length(active_ids))
    println(
        "archive_length: ", length(species.archive), 
        ", mean_archive_size: ", round(archive_size, digits=2))
    println("previous_elite_size: $previous_elite_size")
    println("ids: ", length(species.active_elite_ids))
    println(
        "archive_length: ", length(species.elites), 
        #", mean_archive_size: ", round(archive_size, digits=2)
    )
end

function add_modes_elite_to_archive!(
    rng::AbstractRNG, species::AdaptiveArchiveSpecies, modes_individuals::Vector{<:PruneIndividual}
)
    fitnesses = Dict(
        individual.id => individual.fitness 
        for individual in modes_individuals
    )
    merge!(species.fitnesses, fitnesses)
    sort!(modes_individuals, by = individual -> individual.fitness, rev = true)
    modes_individual = first(modes_individuals)
    modes_individual = BasicIndividual(modes_individual.id, modes_individual.genotype, Int[]) 
    println("MODES ELITE: ", modes_individual.id)
    push!(species.modes_elites, modes_individual)

    basic_individuals = [
        BasicIndividual(individual.id, individual.genotype, Int[]) 
        for individual in modes_individuals
    ]
    add_individuals_to_archive!(rng, species, basic_individuals)
end

# TODO: cant use both archives yet due to negative id hack
function add_elites!(
    species::AdaptiveArchiveSpecies, new_elites::Vector{<:BasicIndividual}, fitnesses::Vector{Float64}
)
    #println("----------------------------------")
    new_elites = [BasicIndividual(-elite.id, elite.genotype, Int[]) for elite in new_elites]

    current_elite_ids = Set([elite.id for elite in species.elites])
    #println("LENGTH BEFORE ADDING: ", length(species.elites))
    for new_elite in new_elites
        if new_elite.id in current_elite_ids
            #println("SKIPPING: ", new_elite.id)
            continue
        end
        push!(species.elites, new_elite)
        #println("ADDING: ", new_elite.id)
    end
    #println("LENGTH AFTER ADDING and BEFORE EJECTING: ", length(species.elites))

    #println("MAX ARCHIVE SIZE: ", species.max_archive_size)

    while length(species.elites) > species.max_archive_size
        # eject the first elements to maintain size
        #println("EJECTING")
        popfirst!(species.elites)
    end
    #println("LENGTH AFTER EJECTING: ", length(species.elites))
    if length(Set([elite.id for elite in species.elites])) != length(species.elites)
        #println("DUPLICATES EXIST")
        throw(ErrorException("DUPLICATES EXIST"))
    end

end

end
# # TODO: add to utils
# function sample_proportionate_to_genotype_size(
#     rng::AbstractRNG, individuals::Vector{<:Individual}, n_sample::Int; 
#     inverse::Bool = false,
#     replace::Bool = false
# )
#     complexity_scores = [get_size(individual.genotype) for individual in individuals]
#     complexity_scores = 1 .+ complexity_scores
#     complexity_scores = inverse ? 1 ./ complexity_scores : complexity_scores
#     weights = Weights(complexity_scores)
#     return sample(rng, individuals, weights, n_sample, replace = replace)
# end