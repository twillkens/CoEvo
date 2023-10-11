
using Test

@testset "Gnarl" begin
println("Starting tests for GnarlNetworks and CollisionGame...")
# include("../../src/CoEvo.jl")
using .CoEvo.Metrics.Concrete.Outcomes.CollisionGameOutcomeMetrics: Affinitive, Adversarial
using .CoEvo.Metrics.Concrete.Outcomes.CollisionGameOutcomeMetrics: Avoidant, Control as GnarlControl
using .CoEvo.Mutators.Types.GnarlNetworks: mutate_weights, add_node, remove_node, add_connection
using .CoEvo.Mutators.Types.GnarlNetworks: remove_connection, mutate

include("individual.jl")
include("collision_game.jl")
include("evolve.jl")

println("Finished tests for GnarlNetworks and CollisionGame.")

end