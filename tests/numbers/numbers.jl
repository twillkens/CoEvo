using Test

"""
    CoEvo Test Suite

This test suite focuses on validating and verifying the functionality of the `CoEvo` module.
The `CoEvo` module provides tools and structures for co-evolutionary simulations.
"""

@testset "Numbers" begin
println("Starting tests for numbers...")

#include("../src/CoEvo.jl")
#using .CoEvo

"""
    NumbersGameProblem with Gradient

Test the `NumbersGameProblem` domain using the `Gradient` strategy. This set
confirms the outcomes when different phenotypes interact within the specified domain.
"""

 @testset "NumbersGameProblem with Gradient" begin
     phenoA = BasicVectorPhenotype([4])  # Vector representation
     phenoB = BasicVectorPhenotype([5])
     domain = NumbersGameDomain(:Gradient)
     env_creator = StatelessEnvironmentCreator(domain)
     env = create_environment(env_creator, Phenotype[phenoA, phenoB])
     outcome_set = get_outcome_set(env)
 
     @test outcome_set[1] == 0.0  # Assuming the first value is for A
     @test outcome_set[2] == 1.0  # Assuming the second value is for B
 
     Sₐ = [BasicVectorPhenotype(x) for x in [[1], [2], [3]]]  # Vector representation for each phenotype
     Sᵦ =  [BasicVectorPhenotype(x) for x in [[6], [7], [8]]]
 
     fitnessA = 0
     for other in Sₐ
         env = create_environment(env_creator, Phenotype[phenoA, other])
         outcome_set = get_outcome_set(env)
         fitnessA += outcome_set[1] == 1.0 ? 1 : 0
     end
     @test fitnessA == 3
 
     fitnessB = 0
     for other in Sᵦ
         env = create_environment(env_creator, Phenotype[phenoB, other])
         outcome_set = get_outcome_set(env)
         fitnessB += outcome_set[1] == 1.0 ? 1 : 0
     end
 
     @test fitnessB == 0
 end
 @testset "NumbersGameProblem with Focusing" begin
     phenoA = BasicVectorPhenotype([4, 16])  # Vector representation
     phenoB = BasicVectorPhenotype([5, 14])
     domain = NumbersGameDomain(:Focusing)
     env_creator = StatelessEnvironmentCreator(domain)
     env = create_environment(env_creator, Phenotype[phenoA, phenoB])
     outcome_set = get_outcome_set(env)
     @test outcome_set[1] == 1.0
 
     phenoB = BasicVectorPhenotype([5, 16])
     env = create_environment(env_creator, Phenotype[phenoA, phenoB])
     outcome_set = get_outcome_set(env)
     @test outcome_set[1] == 0.0
 
     phenoA = BasicVectorPhenotype([5, 16, 8])
     phenoB = BasicVectorPhenotype([4, 16, 6])
     env = create_environment(env_creator, Phenotype[phenoA, phenoB])
     outcome_set = get_outcome_set(env)
     @test outcome_set[1] == 1.0
 end
 
 @testset "NumbersGameProblem with Relativism" begin
     a = BasicVectorPhenotype([1, 6])
     b = BasicVectorPhenotype([4, 5])
     c = BasicVectorPhenotype([2, 4])
     domain = NumbersGameDomain(:Relativism)
     env_creator = StatelessEnvironmentCreator(domain)
 
     env = create_environment(env_creator, Phenotype[a, b])
     outcome_set = get_outcome_set(env)
     @test outcome_set[1] == 1.0
 
     env = create_environment(env_creator, Phenotype[b, c])
     outcome_set = get_outcome_set(env)
     @test outcome_set[1] == 1.0
 
     env = create_environment(env_creator, Phenotype[c, a])
     outcome_set = get_outcome_set(env)
     @test outcome_set[1] == 1.0
 end
 #
 
 @testset "BasicSpeciesCreator" begin
     gen = 1
     rng = StableRNG(42)
     indiv_id_counter = Counter()
     gene_id_counter = Counter()
     species_id = "subjects"
     n_pop = 10
 
     default_vector = collect(1:10)
 
     # Define species configuration similar to spawner
     species_creator = BasicSpeciesCreator(
         id = species_id,
         n_pop = n_pop,
         geno_creator = BasicVectorGenotypeCreator(
             default_vector = default_vector
         ),
         phenotype_creator = DefaultPhenotypeCreator(),
         evaluator = ScalarFitnessEvaluator(),
         replacer = GenerationalReplacer(),
         selector = FitnessProportionateSelector(n_parents = 2),
         recombiner = CloneRecombiner(),
         mutators = [IdentityMutator()],
     )
     species = create_species(species_creator, rng, indiv_id_counter, gene_id_counter) 
     dummy_outcomes = generate_nested_dict(n_pop, n_pop)
     evaluation = create_evaluation(species_creator.evaluator, rng, species, dummy_outcomes)
     reporter = BasicReporter(metric = AllSpeciesFitness())
     species_evaluations = Dict(species => evaluation)
     measurement = measure(reporter, species_evaluations, Observation[])
 #
 end
#
#"""
#    `evolve!` Functionality Test
#
#Tests the primary evolutionary function `evolve!` within a co-evolutionary context.
#Ensures the successful progression of generations and expected state changes.
#"""
#
@testset "evolve!" begin

function dummy_eco_creator(;
    id::String = "test",
    trial::Int = 1,
    rng::AbstractRNG = StableRNG(42),
    n_pop::Int = 2,
    species_id1::String = "a",
    species_id2::String = "b",
    interaction_id::String = "NumbersGame{Sum}",
    default_vector::Vector{Float64} = fill(0.0, 1),
    n_elite::Int = 10
)
    eco_creator = BasicEcosystemCreator(
        id = id,
        trial = trial,
        rng = rng,
        species_creators = Dict(
            species_id1 => BasicSpeciesCreator(
                id = species_id1,
                n_pop = n_pop,
                geno_creator = BasicVectorGenotypeCreator(default_vector = default_vector),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_pop),
                recombiner = CloneRecombiner(),
                mutators = [NoiseInjectionMutator(noise_std = 0.1)],
            ),
            species_id2 => BasicSpeciesCreator(
                id = species_id2,
                n_pop = n_pop,
                geno_creator = BasicVectorGenotypeCreator(default_vector = default_vector),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_pop),
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
    return eco_creator

end

#eco_creator = dummy_eco_creator()

#eco = evolve!(eco_creator, n_gen=10)

eco_creator = dummy_eco_creator(n_pop = 100)
eco = evolve!(eco_creator, n_gen=10)
end

println("Finished tests for numbers...")
end