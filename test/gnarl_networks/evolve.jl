using Test

@testset "Evolve" begin

using CoEvo
using CoEvo.Names

@testset "CollisionGame: Roulette" begin
    configuration = PredictionGameConfiguration(
        substrate = :gnarl_networks,
        reproduction_method = :roulette,
        game = :collision_game,
        ecosystem_topology = :three_species_mix,
        n_population = 10,
        communication_dimension = 1
    )
    ecosystem = run!(configuration, n_generations = 5)
    @test typeof(ecosystem) <: BasicEcosystem
    @test length(ecosystem.species) == 3
end

@testset "CollisionGame: Disco" begin
    configuration = PredictionGameConfiguration(
        substrate = :gnarl_networks,
        reproduction_method = :disco,
        game = :collision_game,
        ecosystem_topology = :three_species_mix,
        n_population = 10,
        communication_dimension = 1
    )

    ecosystem = run!(configuration, n_generations = 5)
    @test typeof(ecosystem) <: BasicEcosystem
    @test length(ecosystem.species) == 3
end

end
