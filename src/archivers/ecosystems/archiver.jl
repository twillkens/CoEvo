export EcosystemArchiver

import ...Archivers: archive!, load

using HDF5: h5open, File
using ...Archivers: Archiver
using ...Individuals: Individual
using ...Individuals.Modes: ModesIndividual
using ...Individuals.Basic: BasicIndividual
using ...Species.Modes: ModesSpecies, get_population, get_pruned, get_pruned_fitnesses, get_elites
using ...Species.Basic: BasicSpecies
using ...Abstract.States: get_ecosystem, get_generation, State
using ...CoEvo.Ecosystems: Ecosystem

struct EcosystemArchiver <: Archiver
    archive_interval::Int
    h5_path::String
end

function archive!(file::File, base_path::String, individual::BasicIndividual)
    genotype_path = "$base_path/genotype"
    archive!(file, genotype_path, individual.genotype)
    file["$base_path/parent_ids"] = individual.parent_ids
end

function archive!(file::File, base_path::String, individual::ModesIndividual)
    file["$base_path/parent_id"] = individual.parent_id
    file["$base_path/tag"] = individual.tag
    file["$base_path/age"] = individual.age
    archive!(file, "$base_path/genotype", individual.genotype)
end

function archive!(file::File, base_path::String, individuals::Vector{<:Individual})
    for individual in individuals
        individual_path = "$base_path/$(individual.id)"
        archive!(file, individual_path, individual)
    end
end

function archive!(file::File, base_path::String, species::ModesSpecies)
    population = get_population(species)
    pruned = get_pruned(species)
    pruned_fitness_ids = [individual.id for individual in pruned]
    pruned_fitnesses = get_pruned_fitnesses(species)
    elites = get_elites(species)
    n_population = length(population)
    n_pruned = length(pruned)
    n_elites = length(elites)
    println("archiving $(species.id): $n_population population, $n_pruned pruned, and $n_elites elites")
    archive!(file, "$base_path/population", population)
    archive!(file, "$base_path/pruned", pruned)
    file["$base_path/pruned_fitness_ids"] = pruned_fitness_ids
    file["$base_path/pruned_fitnesses"] = pruned_fitnesses
    archive!(file, "$base_path/elites", elites)
    #archive!(file, "$base_path/population", get_population(species))
    #archive!(file, "$base_path/pruned", get_pruned(species))
    #file["$base_path/pruned_fitnesses"] = get_pruned_fitnesses(species)
    #archive!(file, "$base_path/elites", get_elites(species))
end

function archive!(file::File, base_path::String, species::BasicSpecies)
    archive!(file, "$base_path/population", species.population)
    archive!(file, "$base_path/children", species.children)
end

function archive!(file::File, base_path::String, ecosystem::Ecosystem)
    for species in ecosystem.species
        species_path = "$base_path/$(species.id)"
        archive!(file, species_path, species)
    end
end

function archive!(archiver::EcosystemArchiver, state::State)
    do_not_archive = archiver.archive_interval == 0
    is_archive_interval = get_generation(state) == 1 ||
        get_generation(state) % archiver.archive_interval == 0
    if do_not_archive || !is_archive_interval
        return
    end
    ecosystem = get_ecosystem(state)
    generation = get_generation(state)
    base_path = "generations/$generation/ecosystem"
    file = h5open(archiver.h5_path, "r+")
    archive!(file, base_path, ecosystem)
    close(file)
    flush(stdout)
end