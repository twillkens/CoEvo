module PredictionGame

export make_prediction_game_experiment, load_prediction_game_experiment

import ..Configurations: run!
import ...Archivers: archive!

using Base: @kwdef
using Random: AbstractRNG
using HDF5: h5write, File, h5open
using ...Names
using ..Configurations: Configuration

include("utilities.jl")

include("globals.jl")

include("topology.jl")

include("games.jl")

include("substrates.jl")

include("reproducers.jl")

include("species_creators.jl")

include("job_creator.jl")

include("report.jl")

include("archiver.jl")

include("ecosystem_creators.jl")

include("experiment.jl")

include("run.jl")

#include("load.jl")

function make_prediction_game_experiment(;
    game::String = "continuous_prediction_game",
    topology::String = "two_control",
    substrate::String = "function_graphs",
    reproducer::String = "disco",
    report::String = "silent",
    kwargs...
)
    globals = GlobalConfiguration(; kwargs...)
    game = get_game(game; kwargs...)
    topology = get_topology(topology)
    substrate = get_substrate(substrate; kwargs...)
    reproducer = get_reproducer(reproducer; kwargs...)
    report = get_report(report; kwargs...)
    configuration = BasicExperiment(
        globals, game, topology, substrate, reproducer, report
    )
    return configuration
end

function load_prediction_game_experiment(path::String)
    file = h5open(path, "r")
    globals = load_globals(file)
    game = load_game(file)
    topology = load_topology(file)
    substrate = load_substrate(file)
    reproducer = load_reproducer(file)
    report = load_report(file)
    close(file)

    configuration = BasicExperiment(
        globals, game, topology, substrate, reproducer, report
    )
    return configuration
end

end