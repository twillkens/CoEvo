module PredictionGame

import ..Configurations: run!

using Base: @kwdef
using Random: AbstractRNG
using HDF5: h5write, File, h5open
using ...Names
using ..Configurations: Configuration, make_random_number_generator

include("configuration.jl")

include("species_creators.jl")

include("job_creator.jl")

include("reporters.jl")

include("ecosystem_creator.jl")

include("run.jl")

include("load.jl")

end