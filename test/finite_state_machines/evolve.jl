using Test

@testset "Evolve" begin

using CoEvo
using .Ecosystems.Basic: BasicEcosystem, BasicEcosystemCreator, make_ecosystem_creator
using .Configurations.PredictionGame: PredictionGameConfiguration

@testset "LinguisticPredictionGame: Roulette" begin
    experiment = make_prediction_game_experiment(
        substrate = "finite_state_machines",
        reproduction_method = "roulette",
        game = "linguistic_prediction_game",
        ecosystem_topology = "three_mixed",
        n_population = 10
    )

    ecosystem_creator = make_ecosystem_creator(experiment)
    @test typeof(ecosystem_creator) <: BasicEcosystemCreator
    ecosystem = evolve!(ecosystem_creator, n_generations = 5)
    @test typeof(ecosystem) <: BasicEcosystem
    @test length(ecosystem.species) == 3
end

end