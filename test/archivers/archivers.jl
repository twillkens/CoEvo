# include("../../src/CoEvo.jl")
using CoEvo

using Test

if isfile("archive.jld2")
    rm("archive.jld2")
end

using Random: AbstractRNG
using StableRNGs: StableRNG
using DataStructures: SortedDict

function generate_nested_dict(first_layer_size::Int, second_layer_size::Int)
    # Initialize an empty dictionary
    my_dict = Dict{Int, SortedDict{Int, Float64}}()

    # Loop for the first layer
    for i in 1:first_layer_size
        # Initialize the second layer dictionary
        second_layer_dict = Dict{Int, Float64}()

        # Loop for the second layer
        for j in (11:(10 + second_layer_size))
            # Generate a random Float64 value between 0 and 1
            random_float = rand()

            # Add the random value to the second layer dictionary
            second_layer_dict[j] = random_float
        end

        # Add the second layer dictionary to the first layer
        my_dict[i] = second_layer_dict
    end
    
    return my_dict
end
using .Metrics.Concrete.Common: AllSpeciesIdentity
using .CoEvo.Loaders.Concrete: EcosystemLoader
using .CoEvo.Loaders.Abstract: Loader

@testset "Archivers" begin
println("Starting tests for Archivers...")

# @testset "BasicSpeciesCreator" begin
#     gen = 1
#     random_number_generator = StableRNG(42)
#     individual_id_counter = Counter()
#     gene_id_counter = Counter()
#     species_id = "Subjects"
#     n_population = 2
# 
#     default_vector = collect(1:10)
# 
#     # Define species configuration similar to spawner
#     species_creator = BasicSpeciesCreator(
#         id = species_id,
#         n_population = n_population,
#         genotype_creator = BasicVectorGenotypeCreator(
#             default_vector = default_vector
#         ),
#         phenotype_creator = DefaultPhenotypeCreator(),
#         evaluator = ScalarFitnessEvaluator(),
#         replacer = GenerationalReplacer(),
#         selector = FitnessProportionateSelector(n_parents = 2),
#         recombiner = CloneRecombiner(),
#         mutators = [IdentityMutator()],
#     )
#     species = create_species(species_creator, random_number_generator, individual_id_counter, gene_id_counter) 
#     dummy_outcomes = generate_nested_dict(n_population, n_population)
#     evaluation = evaluate(species_creator.evaluator, random_number_generator, species, dummy_outcomes)
#     reporter = BasicReporter(metric = AllSpeciesIdentity(), save_interval = 1)
#     species_evaluations = Dict(species => evaluation)
#     measurement = measure(reporter, species_evaluations, Observation[])
#     report = create_report(reporter, gen, species_evaluations, Observation[])
#     archiver = BasicArchiver()
#     archive!(archiver, gen, report)
#     #try
#         loaders = Dict("Subjects" => BasicVectorGenotypeLoader())
#         ecosystem_loader = EcosystemLoader("archive.jld2")
#     ecosystem = load_ecosystem(ecosystem_loader, loaders, gen)
#     @test length(ecosystem.species) == 1
#     @test length(ecosystem.species["Subjects"].pop) == 2
# end

#@testset "Genotype Save and Load Tests" begin
#    # Assume we have a few genotypes defined above
#    genotype = FunctionGraphGenotype(
#        input_node_ids = [1],
#        bias_node_ids = [2],
#        hidden_node_ids = [3, 4],
#        output_node_ids = [5],
#        nodes = Dict(
#            1 => FunctionGraphNode(1, :INPUT, []),
#            2 => FunctionGraphNode(2, :BIAS, []),
#            3 => FunctionGraphNode(3, :ADD, [
#                FunctionGraphConnection(1, 0.5, false),
#                FunctionGraphConnection(2, 0.5, false)
#            ]),
#            4 => FunctionGraphNode(4, :MULTIPLY, [
#                FunctionGraphConnection(3, 0.5, true),
#                FunctionGraphConnection(2, 0.5, false)
#            ]),
#            5 => FunctionGraphNode(5, :OUTPUT, [
#                FunctionGraphConnection(4, 1.0, false)
#            ]),
#        ),
#        n_nodes_per_output = 1
#    )
#
#    archiver = BasicArchiver()
#    
#    # Test saving functionality
#    @testset "Save Genotype" begin
#        @testset "Save $geno_name" for (geno_name, genotype) in [
#            ("test_genotype_1", genotype),
#            #("test_genotype_2", test_genotype_2),
#            # ... additional test genotypes ...
#        ]
#            # Save the genotype to a JLD2 file
#            jldopen("test_save_$geno_name.jld2", "w") do file
#                # Assuming you've defined save_genotype! in a module MyNetworks
#                group = get_or_make_group!(file, "test")
#                save_genotype!(archiver, group, genotype)
#            end
#            # Confirm file exists
#            @test isfile("test_save_$geno_name.jld2")
#        end
#    end
#    
#    # Test loading functionality
#    @testset "Load Genotype" begin
#        @testset "Load $geno_name" for (geno_name, original_geno) in [
#            ("test_genotype_1", genotype),
#            #("test_genotype_2", test_genotype_2),
#            # ... additional test genotypes ...
#        ]
#            # Load the genotype from file
#            loaded_geno = jldopen("test_save_$geno_name.jld2", "r") do file
#                # Assuming you've defined load_genotype in a module MyNetworks
#                group = get_or_make_group!(file, "test")
#                loader = FunctionGraphGenotypeLoader()
#                load_genotype(loader, group)
#            end
#
#            # Verify that the loaded genotype is equal to the original
#            @test loaded_geno == original_geno
#        end
#    end
#end



println("Finished tests for Archivers.")
end