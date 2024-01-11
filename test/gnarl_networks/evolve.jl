using Test

@testset "Evolve" begin

using CoEvo
using CoEvo.Names

#@testset "CollisionGame: Roulette" begin
#    experiment = PredictionGameExperimentConfiguration(
#        game = "collision_game",
#        topology = "three_mixed",
#        substrate = "gnarl_networks",
#        reproduction = "roulette",
#        n_population = 10,
#        communication_dimension = 1,
#        n_generations = 5
#    )
#    state = EvolutionaryState(experiment)
#    state = evolve(state)
#    @test typeof(state) <: EvolutionaryState
#    @test length(get_all_species(state)) == 3
#end
#
#@testset "CollisionGame: Disco" begin
#    experiment = PredictionGameExperimentConfiguration(
#        game = "collision_game",
#        topology = "three_mixed",
#        substrate = "gnarl_networks",
#        reproduction = "disco",
#        clusterer = "xmeans",
#        n_population = 10,
#        communication_dimension = 1,
#        n_generations = 5
#    )
#    state = EvolutionaryState(experiment)
#    state = evolve(state)
#    @test typeof(state) <: EvolutionaryState
#    @test length(get_all_species(state)) == 3
#end

end
