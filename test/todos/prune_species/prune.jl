module Prune

export PruneSpecies, get_individuals, is_fully_pruned
export remove_pruned_individuals, create_phenotype_dict, get_individuals_to_evaluate

import ....Interfaces: create_phenotype_dict, get_individuals_to_evaluate, get_individuals
using ....Abstract

using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual
using ...Species.Basic: BasicSpecies


include("individuals.jl")

struct PruneSpecies{I <: PruneIndividual} <: AbstractSpecies
    id::String
    currents::Vector{I}
    persistent_individuals::Vector{I}
end

function PruneSpecies(id::String, individuals::Vector{PruneIndividual{G}}) where {G <: Genotype}
    to_prune = individuals
    candidates = PruneIndividual{G}[]
    pruned = PruneIndividual{G}[]
    species = PruneSpecies(id, to_prune, candidates, pruned)
    return species
end

function is_fully_pruned(species::PruneSpecies)
    return length(species.currents) == 0
end

function is_fully_pruned(all_species::Vector{<:PruneSpecies})
    return all(is_fully_pruned, all_species)
end

function get_individuals_to_evaluate(species::PruneSpecies)
    individuals = length(species.candidates) == 0 ? 
        species.currents : species.candidates
    return individuals
end

using ...Species: get_population

using ...Genotypes: Genotype

function PruneSpecies(species::ModesSpecies, persistent_tags::Set{Int})
    currents = []
    candidates = []
    pruned = []
    persistent_individuals = filter(
        individual -> individual.id in persistent_tags, species.population
    )
    #println("persistent_ids = : $([individual.id for individual in persistent_individuals])")
    if length(persistent_individuals) == 0
        error("No persistent individuals found.")
    end

    for individual in persistent_individuals
        #genotype = minimize(individual.genotype)
        genotype = individual.genotype
        prune_individual = PruneIndividual(
            -individual.id, genotype, minimize(genotype),
        )
        to_push = is_fully_pruned(prune_individual) ? pruned : currents
        push!(to_push, prune_individual)
    end
    T = length(currents) == 0 ? typeof(first(pruned)) : typeof(first(currents))
    currents = T[current for current in currents]
    candidates = T[candidate for candidate in candidates]
    pruned = T[prune for prune in pruned]
    if (length(currents) + length(candidates) + length(pruned)) != length(persistent_individuals)
        throw(ErrorException("length currents + length candidates + length pruned != " * 
            "length persistent_individuals"))
    end
    species = PruneSpecies(species.id, currents, candidates, pruned)
    dummy_species = PruneSpecies(species.id, T[], [ currents ; candidates ; pruned], T[])
    return species, dummy_species
end

mutable struct ModesPruningState
    ecosystem_creator::EcosystemCreator
    ecosystem::Ecosystem
    results::Vector{R}
    job_creator::JobCreator
    performer::Performer
end

using ...Observers.Modes: StateVectorObserver

function prune_ecosystem(state::State)
    for interaction in state.interactions
        interaction.observer.is_active = true
    end
        
end

include("perform.jl")

end