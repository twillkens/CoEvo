export ModesArchiver

import ....Interfaces: archive!
using ....Interfaces
using ....Abstract
using ...Ecosystems.Simple: SimpleEcosystem
using ...Species.Basic: BasicSpecies
using ...Evaluators.ScalarFitness: ScalarFitnessEvaluator
using HDF5: h5open
using StatsBase: median

Base.@kwdef mutable struct ModesArchiver <: Archiver
    previous_ecosystem = nothing
    all_previous_genotypes = nothing
end

function archive!(archiver::ModesArchiver, state::State)
    if archiver.previous_ecosystem === nothing
        archiver.previous_ecosystem = deepcopy(state.ecosystem)
        archiver.all_previous_genotypes = Set()
        return
    end
    persistent_tags = Int[]
    for species in state.ecosystem.all_species
        for individual in species.population
            push!(persistent_tags, individual.tag)
        end
    end
    println("persistent_tags: ", persistent_tags)
    species_1 = archiver.previous_ecosystem.all_species[1]
    species_2 = archiver.previous_ecosystem.all_species[2]

    persistent_individuals_1 = [
        individual
        for individual in species_1.population
        if individual.tag in persistent_tags
    ]
    println("persistent_ids_1 = ", [individual.id for individual in persistent_individuals_1])
    static_individuals_1 = get_individuals_to_perform(species_1)
    println("static_ids_1 = ", [individual.id for individual in static_individuals_1])
    persistent_individuals_2 = [
        individual
        for individual in species_2.population
        if individual.tag in persistent_tags
    ]
    println("persistent_ids_2 = ", [individual.id for individual in persistent_individuals_2])
    static_individuals_2 = get_individuals_to_perform(species_2)
    println("static_ids_2 = ", [individual.id for individual in static_individuals_2])
    modes_1 = BasicSpecies(species_1.id, persistent_individuals_1)
    modes_2 = BasicSpecies(species_2.id, persistent_individuals_2)
    opponents_1 = BasicSpecies(species_1.id, static_individuals_1)
    opponents_2 = BasicSpecies(species_2.id, static_individuals_2)
    println("starting pruning for species ", modes_1.id)
    prune_species(modes_1, opponents_2, state)
    println("starting pruning for species ", modes_2.id)
    prune_species(modes_2, opponents_1, state)
    for species in state.ecosystem.all_species
        for individual in species.population
            individual.tag = individual.id
        end
    end
    archiver.previous_ecosystem = deepcopy(state.ecosystem)
end

