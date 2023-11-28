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

include("load.jl")




end