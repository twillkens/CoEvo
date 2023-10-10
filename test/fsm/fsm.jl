using Test
using Random
using StableRNGs
using StatsBase
# include("../../src/CoEvo.jl")
using .CoEvo

@testset "FiniteStateMachines" begin
println("Starting tests for FiniteStateMachines and LinguisticPredictionGame...")

include("mutate.jl")
include("hopcroft.jl")
include("equals.jl")
include("simulate.jl")
include("evolve.jl")

println("Finished tests for FiniteStateMachines and LinguisticPredictionGame.")
end