export load, load_prediction_game_experiment, load_ecosystem

import ...Archivers: load

using ...Names
using ...Genotypes.FunctionGraphs: FunctionGraphGenotype, FunctionGraphNode, FunctionGraphConnection
using ...Ecosystems.Basic: BasicEcosystem
using HDF5: File, read, h5open, Group


function load(
    file::File, 
    ::BasicIndividualCreator, 
    genotype_creator::GenotypeCreator,
    gen::Int,
    species_id::String,
    individual_id::Int, 
)
    individual_path = "generations/$gen/species/$species_id/population/$individual_id"
    individual_group = file[individual_path]
    genotype = load(BasicArchiver(), genotype_creator, individual_group["genotype"])
    parent_ids = read(individual_group["parent_ids"])
    individual = BasicIndividual(individual_id, genotype, parent_ids)
    return individual
end


function load(file::File, species_creator::BasicSpeciesCreator, gen::Int)
    species_id = species_creator.id
    population_path = "generations/$gen/species/$species_id/population"
    individual_ids = sort(parse.(Int, keys(file[population_path])))
    individual_creator = species_creator.individual_creator
    genotype_creator = species_creator.genotype_creator

    individuals = [
        load(file, individual_creator, genotype_creator, gen, species_id, individual_id)
        for individual_id in individual_ids
    ]
    population = filter(individual -> first(individual.parent_ids) == individual.id, individuals)
    children = filter(individual -> first(individual.parent_ids) != individual.id, individuals)

    return BasicSpecies(species_id, population, children)
end


function load_prediction_game_experiment(file::File)
    globals = load_globals(file)
    game = load_game(file)
    topology = load_topology(file)
    substrate = load_substrate(file)
    reproducer = load_reproducer(file)
    report = load_report(file)

    experiment = BasicExperiment(
        globals, game, topology, substrate, reproducer, report
    )
    return experiment
end

function load_prediction_game_experiment(path::String)
    file = h5open(path, "r")
    experiment = load_prediction_game_experiment(file)
    close(file)
    return experiment
end

function load_ecosystem(file::File, gen::Int)
    experiment = load_prediction_game_experiment(file)
    ecosystem_creator = make_ecosystem_creator(experiment)
    species_creators = ecosystem_creator.species_creators
    all_species = [
        load(file, species_creator, gen) 
        for species_creator in species_creators
    ]
    return BasicEcosystem("gen_$gen", all_species)
end

function load_ecosystem(path::String, gen::Int)
    file = h5open(path, "r")
    ecosystem = load_ecosystem(file, gen)
    close(file)
    return ecosystem
end