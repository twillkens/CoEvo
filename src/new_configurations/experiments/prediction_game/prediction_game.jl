module PredictionGame

export get_n_generations, make_ecosystem_creator, PredictionGameExperimentConfiguration
export make_job_creator, make_performer, load_prediction_game_experiment
export load_individuals, load_species_state, load_species, load_ecosystem
export load_most_recent_ecosystem

using ...GlobalConfigurations.Basic: BasicGlobalConfiguration
using HDF5: h5open, File, read 

include("subconfigurations/subconfigurations.jl")

include("configuration.jl")

include("create/create.jl")

function PredictionGameExperimentConfiguration(;
    game::String = "continuous_prediction_game",
    topology::String = "two_control",
    substrate::String = "function_graphs",
    reproduction::String = "disco",
    archive::String = "silent",
    kwargs...
)
    globals = get_globals(; kwargs...)
    game = get_game(game; kwargs...)
    topology = get_topology(topology; kwargs...)
    substrate = get_substrate(substrate; kwargs...)
    reproducer = get_reproduction(reproduction; kwargs...)
    archive = get_archive(archive; kwargs...)
    experiment = PredictionGameExperimentConfiguration(
        globals, game, topology, substrate, reproducer, archive
    )
    return experiment
end

function load_prediction_game_experiment(file::File)
    globals = load_globals(file)
    game = load_game(file)
    topology = load_topology(file)
    substrate = load_substrate(file)
    reproduction = load_reproduction(file)
    archive = load_archive(file)

    experiment = PredictionGameExperimentConfiguration(
        globals, game, topology, substrate, reproduction, archive
    )
    return experiment
end

function load_prediction_game_experiment(path::String)
    file = h5open(path, "r")
    experiment = load_prediction_game_experiment(file)
    close(file)
    return experiment
end

using ....Archivers: load
using ....Individuals.Modes: ModesIndividual


function load_individuals(
    file::File, 
    base_path::String,
    species_creator::ModesSpeciesCreator,
)
    individual_ids = sort(parse.(Int, keys(file[base_path])))
    individuals = []
    genotype_creator = species_creator.genotype_creator
    for individual_id in individual_ids
        individual_path = "$base_path/$individual_id"
        individual = ModesIndividual(
            individual_id, 
            read(file["$individual_path/parent_id"]),
            read(file["$individual_path/tag"]),
            read(file["$individual_path/age"]),
            load(file, "$individual_path/genotype", genotype_creator),
        )
        push!(individuals, individual)
    end
    individuals = [individual for individual in individuals]
    return individuals
end

using ....Species.Modes: ModesCheckpointState

function load_species_state(file::File, species_creator::ModesSpeciesCreator, gen::Int)
    species_id = species_creator.id
    base_path = "generations/$gen/ecosystem/$species_id"

    population = load_individuals(file, "$base_path/population", species_creator)
    sort!(population, by = individual -> individual.id)
    I = typeof(first(population))
    if "pruned" ∉ keys(file[base_path])
        pruned = I[]
        pruned_fitnesses = Float64[]
    else
        pruned = load_individuals(file, "$base_path/pruned", species_creator)
        pruned_fitnesses = read(file["$base_path/pruned_fitnesses"])
    end
    if "elites" ∉ keys(file[base_path])
        elites = I[]
    else 
        elites = load_individuals(file, "$base_path/elites", species_creator)
    end
    state = ModesCheckpointState(
        population = population,
        pruned = pruned,
        pruned_fitnesses = pruned_fitnesses,
        elites = elites,
    )
    return state

end

using ....Species.Modes: ModesSpecies

function load_species(
    file::File, 
    species_creator::ModesSpeciesCreator, 
    gen::Int
)
    state = load_species_state(file, species_creator, gen)
    if gen == 1
        species = ModesSpecies(species_creator.id, state.population)
        return species
    end
    generations = [parse(Int, key) for key in keys(file["generations"])]
    all_previous_pruned = Set(individual.genotype for individual in state.pruned)
    previous_generations = filter(generation -> generation < gen, generations)
    for previous_gen in previous_generations
        previous_state = load_species_state(
            file, species_creator, previous_gen
        )
        previous_pruned_genotypes = Set(individual.genotype for individual in previous_state.pruned)
        all_previous_pruned = union(all_previous_pruned, previous_pruned_genotypes)
    end

    species = ModesSpecies(
        id = species_creator.id, 
        current_state = state,
        previous_state = state,
        all_previous_pruned = all_previous_pruned,
        change = Int(read(file["generations/$gen/modes/change"])),
        novelty = Int(read(file["generations/$gen/modes/novelty"]))
    )
    println("loaded_ids_$(species_creator.id) = ", [individual.id for individual in state.population])
    return species
end

using ....Ecosystems.Simple: SimpleEcosystem

function load_ecosystem(file::File, gen::Int)
    experiment = load_prediction_game_experiment(file)
    ecosystem_creator = make_ecosystem_creator(experiment)
    species_creators = ecosystem_creator.species_creators
    all_species = [
        load_species(file, species_creator, gen) for species_creator in species_creators
    ]
    return SimpleEcosystem(experiment.id, all_species)
end

function load_ecosystem(path::String, gen::Int)
    file = h5open(path, "r")
    ecosystem = load_ecosystem(file, gen)
    close(file)
    return ecosystem
end

function load_most_recent_ecosystem(file::File)
    generations = [parse(Int, key) for key in keys(file["generations"])]
    println("generations = ", generations)
    gen = maximum(generations)
    println("gen = ", gen)
    ecosystem = load_ecosystem(file, gen)
    return ecosystem
end

function load_most_recent_ecosystem(path::String)
    file = h5open(path, "r")
    ecosystem = load_most_recent_ecosystem(file)
    close(file)
    return ecosystem
end

using HDF5: delete_object

export delete_most_recent_checkpoint

function delete_most_recent_checkpoint(file::File)
    generations = [parse(Int, key) for key in keys(file["generations"])]
    gen = maximum(generations)
    delete_object(file, "generations/$gen")
end



end