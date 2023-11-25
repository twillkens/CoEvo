using Test

@testset "Evolve" begin

using CoEvo
using CoEvo.Names

@testset "CollisionGame: Roulette" begin
    experiment = make_prediction_game_experiment(
        game = "collision_game",
        topology = "three_mixed",
        substrate = "gnarl_networks",
        reproducer = "roulette",
        n_population = 10,
        communication_dimension = 1
    )
    ecosystem = run!(experiment, n_generations = 5)
    @test typeof(ecosystem) <: BasicEcosystem
    @test length(ecosystem.species) == 3
end

@testset "CollisionGame: Disco" begin
    experiment = make_prediction_game_experiment(
        game = "collision_game",
        topology = "three_mixed",
        substrate = "gnarl_networks",
        reproducer = "disco",
        n_population = 10,
        communication_dimension = 1
    )

    ecosystem = run!(experiment, n_generations = 5)
    @test typeof(ecosystem) <: BasicEcosystem
    @test length(ecosystem.species) == 3
end

end
