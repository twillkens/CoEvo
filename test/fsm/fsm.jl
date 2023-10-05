using Test
using Random
using StableRNGs
using StatsBase
include("../../src/CoEvo.jl")
using .CoEvo

include("mutate.jl")
include("hopcroft.jl")
include("equals.jl")
include("simulate.jl")
#include("evolove.jl")