using Test
using Random
using StableRNGs
using StatsBase
# include("../../src/CoEvo.jl")
using .CoEvo

@testset "FiniteStateMachines" begin

include("mutate.jl")
include("hopcroft.jl")
include("equals.jl")
include("simulate.jl")
include("evolve.jl")

end