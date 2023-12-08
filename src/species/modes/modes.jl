module Modes

export ModesSpecies, get_individuals

import ...Individuals: get_individuals
import ...Individuals.Modes: is_fully_pruned

using ...Genotypes: minimize, Genotype
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual
using ...Species: AbstractSpecies
using ...Species.Basic: BasicSpecies

struct ModesSpecies{I <: BasicIndividual, M <: ModesIndividual} <: AbstractSpecies
    id::String
    normal_individuals::Vector{I}
    modes_individuals::Vector{M}
end

function is_fully_pruned(species::ModesSpecies)
    return length(species.modes_individuals) == 0
end

function is_fully_pruned(all_species::Vector{<:ModesSpecies})
    return all(is_fully_pruned, all_species)
end

function get_individuals(species::ModesSpecies)
    all_individuals = [species.normal_individuals ; species.modes_individuals]
    return all_individuals
end

function ModesSpecies(
    species::BasicSpecies{BasicIndividual{G}}, persistent_ids::Set{Int}
) where {G <: Genotype}
    normal_individuals = get_individuals(species)
    modes_individuals = ModesIndividual{G}[]
    for individual in normal_individuals
        if individual.id in persistent_ids
            genotype = minimize(individual.genotype)
            # println("chosen: ", individual.id, ", from ", persistent_ids, ", with size: ", get_size(genotype))
            modes_individual = ModesIndividual(-individual.id, genotype)
            push!(modes_individuals, modes_individual)
        end
    end
    #println(modes_individuals)
    modes_species = ModesSpecies(species.id, normal_individuals, modes_individuals)
    return modes_species
end

# Function to create ModesSpecies objects
function create_modes_species(all_species::Vector{<:AbstractSpecies}, persistent_ids::Set{Int})
    modes_species = [ModesSpecies(species, persistent_ids) for species in all_species]
    return modes_species
end

# Function to prune individuals
function prune_individuals!(
    species::ModesSpecies, pruned_individuals::Vector{<:ModesIndividual}
)
    pruned_ids = Set{Int}()
    for individual in species.modes_individuals
        if is_fully_pruned(individual)
            push!(pruned_individuals, individual)
            push!(pruned_ids, individual.id)
        end
    end
    filter!(individual -> individual.id ∉ pruned_ids, species.modes_individuals)
    return pruned_ids
end

end