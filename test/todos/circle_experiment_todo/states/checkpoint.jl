export create_archive_directory, evolve!, load_state

using HDF5
import ....Interfaces: evolve!
using ....Utilities
using ....Abstract
using ....Interfaces
using ...States.Basic: BasicEvolutionaryState

function create_archive_directory(config::CircleExperimentConfiguration)
    archive_directory = config.archive_directory
    println("Creating new archive directory at $archive_directory")
    println("config = $config")
    mkpath(archive_directory)
    config_file = h5open("$archive_directory/configuration.h5", "w")
    config_dict = convert_to_dict(config)
    save_dict_to_hdf5!(config_file, "configuration", config_dict,)
    config_file["git_commit_hash"] = get_git_commit_hash()
    config_file["launch_datetime"] = current_date_time()
    close(config_file)
    flush(stdout)
end

function load_state(config::CircleExperimentConfiguration, generation::Int)
    archive_directory = config.archive_directory
    checkpoint_path = joinpath(archive_directory, "generations", "$generation.h5")
    state_dict = load_dict_from_hdf5(checkpoint_path, "state")
    state = create_state_from_dict(state_dict, config)
    return state
end

function load_state(config::CircleExperimentConfiguration, checkpoint_path::String)
    state_dict = load_dict_from_hdf5(checkpoint_path, "/")
    state = create_state_from_dict(state_dict, config)
    return state
end

function load_state_from_checkpoint(config::CircleExperimentConfiguration)
    archive_directory = config.archive_directory
    println("Loading archive from $archive_directory")
    println("config = $config")
    checkpoint_path = find_recent_valid_checkpoint_path(archive_directory)
    
    if checkpoint_path !== nothing
        state = load_state(config, checkpoint_path)
    else
        println("No valid checkpoints found. Reinitializing state.")
        state = create_state(config)
    end
    #sort!(state.ecosystem.all_species, by = x -> x.id)
    # First, create a dictionary that maps id to its order in y for fast lookup
    #println("ecosystem_after_load = $(state.ecosystem)")
    flush(stdout)
    return state
end

function initialize_state(config::CircleExperimentConfiguration)
    if !isdir(config.archive_directory)
        create_archive_directory(config)
        state = create_state(config)
    else
        state = load_state_from_checkpoint(config)
    end
    return state
end
