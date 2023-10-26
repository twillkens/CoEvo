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



@testset "evolve!" begin

function dummy_eco_creator(;
    id::String = "test",
    trial::Int = 1,
    random_number_generator::AbstractRNG = StableRNG(42),
    n_population::Int = 2,
    species_id1::String = "a",
    species_id2::String = "b",
    interaction_id::String = "NumbersGame{Sum}",
    default_vector::Vector{Float64} = fill(0.0, 1),
    n_elite::Int = 10
)
    ecosystem_creator = BasicEcosystemCreator(
        id = id,
        trial = trial,
        random_number_generator = random_number_generator,
        species_creators = Dict(
            species_id1 => BasicSpeciesCreator(
                id = species_id1,
                n_population = n_population,
                genotype_creator = BasicVectorGenotypeCreator(default_vector = default_vector),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_population),
                recombiner = CloneRecombiner(),
                mutators = [NoiseInjectionMutator(noise_std = 0.1)],
            ),
            species_id2 => BasicSpeciesCreator(
                id = species_id2,
                n_population = n_population,
                genotype_creator = BasicVectorGenotypeCreator(default_vector = default_vector),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_population),
                recombiner = CloneRecombiner(),
                mutators = [NoiseInjectionMutator(noise_std = 0.1)],
            ),
        ),
        job_creator = BasicJobCreator(
            n_workers = 1,
            interactions = Dict(
                interaction_id => BasicInteraction(
                    id = interaction_id,
                    environment_creator = StatelessEnvironmentCreator(NumbersGameDomain(:Sum)),
                    species_ids = [species_id1, species_id2],
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                ),
            ),
        ),
        performer = BasicPerformer(n_workers = 1),
        reporters = Reporter[
            #BasicReporter(metric = AllSpeciesFitness()),
            #BasicReporter(metric = GenotypeSum())
        ],
        archiver = BasicArchiver(),
        runtime_reporter = RuntimeReporter(print_interval = 0),
    )
    return ecosystem_creator

end

#ecosystem_creator = dummy_eco_creator()

#eco = evolve!(ecosystem_creator, n_generations=10)

#ecosystem_creator = dummy_eco_creator(n_population = 100)
#eco = evolve!(ecosystem_creator, n_generations=10)
end

println("Finished tests for Archivers.")
end