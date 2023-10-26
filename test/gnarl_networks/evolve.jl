using Test

@testset "Evolve" begin

using CoEvo
using .Ecosystems.Basic: BasicEcosystem, BasicEcosystemCreator
using .Configurations: make_ecosystem_creator
using .Configurations.PredictionGame: PredictionGameConfiguration

@testset "CollisionGame: Roulette" begin
    configuration = PredictionGameConfiguration(
        substrate = :gnarl_networks,
        reproduction_method = :roulette,
        game = :collision_game,
        ecosystem_topology = :three_species_mix,
        n_population = 10
    )

    ecosystem_creator = make_ecosystem_creator(configuration)
    @test typeof(ecosystem_creator) <: BasicEcosystemCreator
    ecosystem = evolve!(ecosystem_creator, n_generations = 5)
    @test typeof(ecosystem) <: BasicEcosystem
    @test length(ecosystem.species) == 3
end

@testset "CollisionGame: Disco" begin
    configuration = PredictionGameConfiguration(
        substrate = :gnarl_networks,
        reproduction_method = :disco,
        game = :collision_game,
        ecosystem_topology = :three_species_mix,
        n_population = 10
    )

    ecosystem_creator = make_ecosystem_creator(configuration)
    @test typeof(ecosystem_creator) <: BasicEcosystemCreator
    ecosystem = evolve!(ecosystem_creator, n_generations = 5)
    @test typeof(ecosystem) <: BasicEcosystem
    @test length(ecosystem.species) == 3

end

end
