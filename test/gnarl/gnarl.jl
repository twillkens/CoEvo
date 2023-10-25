
using Test

@testset "Gnarl" begin

println("Starting tests for GnarlNetworks and CollisionGame...")

using CoEvo



include("individual.jl")
#include("collision_game.jl")
#include("evolve.jl")

println("Finished tests for GnarlNetworks and CollisionGame.")

end