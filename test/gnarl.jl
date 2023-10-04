using Test
using Random
using StableRNGs: StableRNG
include("../src/CoEvo.jl")
using .CoEvo
using .Mutators.Types.GnarlNetworks: mutate_weights, add_node, remove_node, add_connection, remove_connection, mutate


# Mock the required external modules/functions for testing purposes

# Create a basic genotype to work with
basic_genotype() = GnarlNetworkGenotype(
    2,
    1,
    [GnarlNetworkNodeGene(1, 0.3f0), GnarlNetworkNodeGene(2, 0.4f0)],
    [GnarlNetworkConnectionGene(1, 0.3f0, 0.4f0, 0.5f0)]
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
        mutated_geno = remove_node(rng, counter, geno)
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
        mutated_geno = remove_connection(rng, counter, geno)
        @test isempty(mutated_geno.connections)
    end

    @testset "mutate" begin
        geno = basic_genotype()
        mutated_geno = mutate(mutator, rng, counter, geno)
        @test mutated_geno ≠ geno
        # Note: Depending on the random mutations, more specific checks might be added.
    end

end
@testset "GnarlNetworks Genotypes Tests" begin

    rng = Random.MersenneTwister(1234)  # Deterministic RNG for reproducibility
    counter = Counter(1)
    genotype_creator = GnarlNetworkGenotypeCreator(2, 1)

    @testset "Genotype creation" begin
        genotypes = create_genotypes(genotype_creator, rng, counter, 5)
        @test length(genotypes) == 5
        for geno in genotypes
            @test geno.n_input_nodes == 2
            @test geno.n_output_nodes == 1
            @test isempty(geno.hidden_nodes)
            @test isempty(geno.connections)
        end
    end

    @testset "Genotype basic structure" begin
        geno = basic_genotype()
        @test geno.n_input_nodes == 2
        @test geno.n_output_nodes == 1
        @test length(geno.hidden_nodes) == 2
        @test length(geno.connections) == 1
        @test geno.connections[1].origin == 0.3f0
        @test geno.connections[1].destination == 0.4f0
    end
end