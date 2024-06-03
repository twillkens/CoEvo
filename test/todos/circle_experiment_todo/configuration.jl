export CircleExperimentConfiguration

import ....Interfaces: create_from_dict, convert_to_dict
using ....Abstract

Base.@kwdef struct CircleExperimentConfiguration <: Configuration
    id::Int = 1
    n_generations::Int = 20_000
    seed::Int = 72
    n_ecosystems::Int = 1
    n_workers_per_ecosystem::Int = 1
    checkpoint_interval::Int = 100
    # GAME
    episode_length::Int = 16
    # TOPOLOGY
    topology::String = "two_competitive"
    # SPECIES
    species::String = "small"
    #SUBSTRATE
    mutator::String = "shrink_moderate"
    # EVALUATION
    evaluator::String = "disco"
    # SELECTION
    selector::String = "tournament"
    # MODES
end

function convert_to_dict(config::CircleExperimentConfiguration)
    dict = Dict(
        "config_type" => "circle",
        "id" => config.id,
        "n_generations" => config.n_generations,
        "seed" => config.seed,
        "n_ecosystems" => config.n_ecosystems,
        "n_workers_per_ecosystem" => config.n_workers_per_ecosystem,
        "episode_length" => config.episode_length,
        "topology" => config.topology,
        "species" => config.species,
        "mutator" => config.mutator,
        "evaluator" => config.evaluator,
        "selector" => config.selector,
    )
    return dict
end

function create_from_dict(::CircleExperimentConfiguration, dict::Dict)
    config = CircleExperimentConfiguration(
        id = dict["id"],
        n_generations = dict["n_generations"],
        seed = dict["seed"],
        n_ecosystems = dict["n_ecosystems"],
        n_workers_per_ecosystem = dict["n_workers_per_ecosystem"],
        episode_length = dict["episode_length"],
        topology = dict["topology"],
        species = dict["species"],
        mutator = dict["mutator"],
        evaluator = dict["evaluator"],
        selector = dict["selector"],
    )
    return config
end

function get_archive_directory(config::CircleExperimentConfiguration)
    fields = [
        ENV["COEVO_TRIAL_DIR"], 
        string(config.id), config.topology, config.species, config.mutator, config.evaluator
    ]
    archive_directory = joinpath(fields)
    return archive_directory
end

function Base.getproperty(config::CircleExperimentConfiguration, property::Symbol) 
    if property == :archive_directory
        return get_archive_directory(config)
    else
        return getfield(config, property)
    end
end