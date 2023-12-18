module Prune

export PruneSpecies, get_individuals, is_fully_pruned
export remove_pruned_individuals, create_phenotype_dict, get_individuals_to_evaluate

import ...Individuals: get_individuals
import ...Individuals.Prune: is_fully_pruned
import ...Species: create_phenotype_dict, get_individuals_to_evaluate

using ...Individuals.Prune: PruneIndividual
using ...Genotypes: minimize, Genotype
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual
using ...Individuals.Prune: PruneIndividual, modes_prune
using ...Species: AbstractSpecies
using ...Species.Basic: BasicSpecies
using ...Phenotypes: create_phenotype, PhenotypeCreator

using ...Species.Modes: ModesSpecies, get_persistent_tags

struct PruneSpecies{I <: PruneIndividual} <: AbstractSpecies
    id::String
    currents::Vector{I}
    candidates::Vector{I}
    pruned::Vector{I}
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


function PruneSpecies(species::ModesSpecies{I}) where {I <: ModesIndividual}
    persistent_tags = get_persistent_tags(species)
    #println("persistent_tags = $persistent_tags")
    #println("species.previous_population: $(species.previous_population)")
    currents = []
    candidates = []
    pruned = []
    persistent_individuals = [
        individual for individual in species.previous_population 
        if individual.tag in persistent_tags
    ]
    #println("persistent_ids = : $([individual.id for individual in persistent_individuals])")
    if length(persistent_individuals) == 0
        throw(ErrorException("No persistent individuals found."))
    end

    for individual in persistent_individuals
        #genotype = minimize(individual.genotype)
        genotype = individual.genotype
        prune_individual = PruneIndividual(-individual.id, genotype, minimize(genotype))
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
    return species
end

end