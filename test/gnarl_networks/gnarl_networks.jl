using Test

@testset "Gnarl" begin

println("Starting tests for GnarlNetworks and CollisionGame...")

include("individual.jl")
include("remove_node.jl")
include("collision_game.jl")
include("evolve.jl")

println("Finished tests for GnarlNetworks and CollisionGame.")

end