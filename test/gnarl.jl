using Test
using Random
using StableRNGs: StableRNG
#include("../src/CoEvo.jl")
using .CoEvo
using .Mutators.Types.GnarlNetworks: mutate_weights, add_node, remove_node, add_connection, remove_connection, mutate


# Mock the required external modules/functions for testing purposes

# Create a basic genotype to work with
basic_genotype() = GnarlNetworkGenotype(
    2,
    1,
    [GnarlNetworkNodeGene(1, 1.0f0), GnarlNetworkNodeGene(2, 2.0f0)],
    [GnarlNetworkConnectionGene(1, 1.0f0, 2.0f0, 0.5f0)]
)

@testset "GnarlNetworks Mutation Tests" begin

    rng = StableRNG(42)
    counter = Counter(1)
    mutator = GnarlNetworkMutator()

    @testset "mutate_weight" begin
        geno = basic_genotype()
        original_weight = geno.connections[1].weight
        mutated_geno = mutate_weights(rng, geno, mutator.weight_factor)
        @test mutated_geno.connections[1].weight ≠ original_weight
    end

    @testset "add_node" begin
        geno = basic_genotype()
        mutated_geno = add_node(rng, counter, geno)
        @test length(mutated_geno.hidden_nodes) == length(geno.hidden_nodes) + 1
    end

    @testset "remove_node" begin
        geno = basic_genotype()
        mutated_geno = remove_node(rng, geno)
        # We have a single hidden node in the basic_genotype so it should be removed
        @test length(mutated_geno.hidden_nodes) == 1
    end

    @testset "add_connection" begin
        geno = basic_genotype()
        mutated_geno = add_connection(rng, counter, geno)
        @test length(mutated_geno.connections) == length(geno.connections) + 1
    end

    @testset "remove_connection" begin
        geno = basic_genotype()
        mutated_geno = remove_connection(rng, geno)
        @test isempty(mutated_geno.connections)
    end

    @testset "mutate" begin
        geno = basic_genotype()
        mutated_geno = mutate(mutator, rng, counter, geno)
        @test mutated_geno ≠ geno
        # Note: Depending on the random mutations, more specific checks might be added.
    end

end
