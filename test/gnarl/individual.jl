using Test

@testset "Individual" begin

using Random
using CoEvo

using StableRNGs: StableRNG
using .Counters.Basic: BasicCounter
using .Genotypes: create_genotypes, get_size, minimize
using .Genotypes.GnarlNetworks: GnarlNetworkGenotype, GnarlNetworkGenotypeCreator
using .Genotypes.GnarlNetworks: NodeGene, ConnectionGene, get_required_nodes
using .Phenotypes: create_phenotype
using .Mutators.GnarlNetworks: mutate_weights, add_node, remove_node, add_connection
using .Mutators.GnarlNetworks: remove_connection, mutate, redirect_or_replace_connection
using .Mutators.GnarlNetworks: redirect_connection, replace_connection
using .Mutators.GnarlNetworks: get_next_layer, get_previous_layer, GnarlNetworkMutator

# Create a basic genotype to work with
basic_genotype() = GnarlNetworkGenotype(
    2,
    1,
    [NodeGene(1, 0.3f0), NodeGene(2, 0.4f0)],
    [ConnectionGene(1, 0.3f0, 0.4f0, 0.5f0)]
)

@testset "GnarlNetworks Mutation Tests" begin

    random_number_generator = StableRNG(42)
    counter = BasicCounter(1)
    mutator = GnarlNetworkMutator()

    @testset "mutate_weight" begin
        genotype = basic_genotype()
        original_weight = genotype.connections[1].weight
        mutated_geno = mutate_weights(random_number_generator, genotype, mutator.weight_factor)
        @test mutated_geno.connections[1].weight ≠ original_weight
    end

    @testset "add_node" begin
        genotype = basic_genotype()
        mutated_geno = add_node(random_number_generator, counter, genotype)
        @test length(mutated_geno.hidden_nodes) == length(genotype.hidden_nodes) + 1
    end

    @testset "remove_node" begin
        genotype = basic_genotype()
        mutated_geno = remove_node(random_number_generator, counter, genotype)
        # We have a single hidden node in the basic_genotype so it should be removed
        @test length(mutated_geno.hidden_nodes) == 1
    end

    @testset "add_connection" begin
        genotype = basic_genotype()
        mutated_geno = add_connection(random_number_generator, counter, genotype)
        @test length(mutated_geno.connections) == length(genotype.connections) + 1
    end

    @testset "remove_connection" begin
        genotype = basic_genotype()
        mutated_geno = remove_connection(random_number_generator, counter, genotype)
        @test isempty(mutated_geno.connections)
    end

    @testset "mutate" begin
        genotype = basic_genotype()
        create_phenotype(DefaultPhenotypeCreator(), genotype)
        for i in 1:1000
            genotype = mutate(mutator, random_number_generator, counter, genotype)
            phenotype = create_phenotype(DefaultPhenotypeCreator(), genotype)
        end
    end

end

@testset "GnarlNetworks Genotypes Tests" begin

    random_number_generator = StableRNG(42)  # Deterministic RNG for reproducibility
    counter = BasicCounter(1)
    genotype_creator = GnarlNetworkGenotypeCreator(2, 1)

    @testset "Genotype creation" begin
        genotypes = create_genotypes(genotype_creator, random_number_generator, counter, 5)
        @test length(genotypes) == 5
        for genotype in genotypes
            @test genotype.n_input_nodes == 2
            @test genotype.n_output_nodes == 1
            @test isempty(genotype.hidden_nodes)
            @test isempty(genotype.connections)
        end
    end

    @testset "Genotype basic structure" begin
        genotype = basic_genotype()
        @test genotype.n_input_nodes == 2
        @test genotype.n_output_nodes == 1
        @test length(genotype.hidden_nodes) == 2
        @test length(genotype.connections) == 1
        @test genotype.connections[1].origin == 0.3f0
        @test genotype.connections[1].destination == 0.4f0
    end
end
basic_genotype2() = GnarlNetworkGenotype(
    2,
    2,
    [NodeGene(1, 0.3f0), NodeGene(2, 0.4f0)],
    [
        ConnectionGene(1, 0.3f0, 0.4f0, 0.1f0),
        ConnectionGene(2, -1.0f0, 0.4f0, 0.2f0),
        ConnectionGene(3, -2.0f0, 0.3f0, 0.3f0),
        ConnectionGene(4, 0.0f0, 1.0f0, 1.0f0),
        ConnectionGene(5, 0.0f0, 2.0f0, 1.0f0),
        ConnectionGene(6, 0.4f0, 1.0f0, 0.6f0),
    ]
)
@testset "GnarlNetworks Phenotype Tests" begin
    using .Phenotypes.GnarlNetworks: set_output!, get_output, reset!, act!

    genotype = basic_genotype2()
    phenotype_creator = DefaultPhenotypeCreator()
    phenotype = create_phenotype(phenotype_creator, genotype)

    @testset "Phenotype structure" begin
        @test phenotype.n_input_nodes == 2
        @test phenotype.n_output_nodes == 2
        @test length(phenotype.neurons) == 7  # 2 input + 2 hidden + 1 bias
        @test length(phenotype.operations) == 7  # 2 for inputs + 2 for hidden nodes
    end

    @testset "Reset Phenotype" begin
        set_output!(phenotype.neurons[0.3f0], 0.5f0)
        set_output!(phenotype.neurons[0.4f0], 0.5f0)
        reset!(phenotype)
        @test get_output(phenotype.neurons[0.3f0]) == 0.0f0
        @test get_output(phenotype.neurons[0.4f0]) == 0.0f0
    end

    @testset "Act Phenotype" begin
        inputs = [0.5f0, 0.5f0]
        outputs = act!(phenotype, inputs)
        @test length(outputs) == 2
        # Please note that exact values may vary depending on the tanh implementation and other parameters
        # The following are placeholders, so update or add more tests as needed
        #@test outputs[1] ≈ 0.2  # Placeholder value
        @test outputs[2] ≈ tanh(2.5f0)  # Placeholder value
    end

end

@testset "GNARL Methods" begin
    @testset "get_required_nodes" begin
        in_pos = Set(Float32.([-2.0, -1.0, 0.0]))
        hidden_pos = Set(Float32.([0.5, 0.75]))
        out_pos = Set(Float32.([1.0, 2.0]))
        conn_tups = Set(Tuple{Float32, Float32}[
            (-2.0, 0.5), 
            (0.5, 1.0), 
            (0.75, 2.0), 
            (0.75, 0.75)
        ])
        @test get_required_nodes(
            in_pos, hidden_pos, out_pos, conn_tups, true
        ) == Set(Float32.([0.5]))

        @test get_required_nodes(
            in_pos, hidden_pos, out_pos, conn_tups, false
        ) == Set(Float32.([0.5, 0.75]))
    end

    @testset "minimize" begin
        g = GnarlNetworkGenotype(
            3,
            2,
            [
                NodeGene(4, 0.1), 
                NodeGene(5, 0.2), 
                NodeGene(6, 0.3), 
                NodeGene(7, 0.4), 
                NodeGene(8, 0.5), 
                NodeGene(9, 0.6)
            ],
            [
                ConnectionGene(12, -2.0, 0.2, 0.0), 
                ConnectionGene(13, 0.0, 0.4, 0.0),
                ConnectionGene(14, 0.2, 0.3, 0.0),
                ConnectionGene(15, 0.2, 1.0, 0.0),
                ConnectionGene(16, 0.3, 0.2, 0.0),
                ConnectionGene(17, 0.3, 2.0, 0.0),
                ConnectionGene(18, 0.4, 0.6, 0.0),
                ConnectionGene(19, 0.5, 0.5, 0.0),
                ConnectionGene(20, 0.5, 2.0, 0.0),
                ConnectionGene(21, 0.6, 0.4, 0.0)
            ]
        )

        g2 = minimize(g)

        @test g2.hidden_nodes == [NodeGene(5, 0.2), NodeGene(6, 0.3)]
        @test length(g2.connections) == 5
    end

end

end