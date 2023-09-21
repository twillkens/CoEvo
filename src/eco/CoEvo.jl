using DataStructures
using Random
using StableRNGs

abstract type Ecosystem end
abstract type EcosystemConfiguration end 

include("util.jl")
include("species.jl")
include("observation.jl")
include("matchmaker.jl")
include("domain.jl")
include("job.jl")
include("eco.jl")