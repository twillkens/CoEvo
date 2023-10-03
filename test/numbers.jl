using Test

"""
    CoEvo Test Suite

This test suite focuses on validating and verifying the functionality of the `CoEvo` module.
The `CoEvo` module provides tools and structures for co-evolutionary simulations.
"""

@testset "CoEvo" begin

using Random: AbstractRNG
using StableRNGs: StableRNG
using DataStructures: OrderedDict
include("../src/CoEvo.jl")
using .CoEvo

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
    env = create_environment(env_creator, [phenoA, phenoB])
    outcome_set = get_outcome_set(env)

    @test outcome_set[1] == 0.0  # Assuming the first value is for A
    @test outcome_set[2] == 1.0  # Assuming the second value is for B

    Sₐ = [BasicVectorPhenotype(x) for x in [[1], [2], [3]]]  # Vector representation for each phenotype
    Sᵦ =  [BasicVectorPhenotype(x) for x in [[6], [7], [8]]]

    fitnessA = 0
    for other in Sₐ
        env = create_environment(env_creator, [phenoA, other])
        outcome_set = get_outcome_set(env)
        fitnessA += outcome_set[1] == 1.0 ? 1 : 0
    end
    @test fitnessA == 3

    fitnessB = 0
    for other in Sᵦ
        env = create_environment(env_creator, [phenoB, other])
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
    env = create_environment(env_creator, [phenoA, phenoB])
    outcome_set = get_outcome_set(env)
    @test outcome_set[1] == 1.0

    phenoB = BasicVectorPhenotype([5, 16])
    env = create_environment(env_creator, [phenoA, phenoB])
    outcome_set = get_outcome_set(env)
    @test outcome_set[1] == 0.0

    phenoA = BasicVectorPhenotype([5, 16, 8])
    phenoB = BasicVectorPhenotype([4, 16, 6])
    env = create_environment(env_creator, [phenoA, phenoB])
    outcome_set = get_outcome_set(env)
    @test outcome_set[1] == 1.0
end

@testset "NumbersGameProblem with Relativism" begin
    a = BasicVectorPhenotype([1, 6])
    b = BasicVectorPhenotype([4, 5])
    c = BasicVectorPhenotype([2, 4])
    domain = NumbersGameDomain(:Relativism)
    env_creator = StatelessEnvironmentCreator(domain)

    env = create_environment(env_creator, [a, b])
    outcome_set = get_outcome_set(env)
    @test outcome_set[1] == 1.0

    env = create_environment(env_creator, [b, c])
    outcome_set = get_outcome_set(env)
    @test outcome_set[1] == 1.0

    env = create_environment(env_creator, [c, a])
    outcome_set = get_outcome_set(env)
    @test outcome_set[1] == 1.0
end
#
function generate_nested_dict(first_layer_size::Int, second_layer_size::Int)
    # Initialize an empty dictionary
    my_dict = Dict{Int, Dict{Int, Float64}}()

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
        pheno_creator = DefaultPhenotypeCreator(),
        evaluator = ScalarFitnessEvaluator(),
        replacer = GenerationalReplacer(),
        selector = FitnessProportionateSelector(n_parents = 2),
        recombiner = CloneRecombiner(),
        mutators = [IdentityMutator()],
    )
    species = create_species(species_creator, rng, indiv_id_counter, gene_id_counter) 
    dummy_outcomes = generate_nested_dict(n_pop, n_pop)
    evaluation = create_evaluation(species_creator.evaluator, species, dummy_outcomes)
    reporter = BasicReporter(metric = TestBasedFitness())
    species_evaluations = Dict(species => evaluation)
    measurement = measure(reporter, species_evaluations)
    println(measurement)
#
#    # Test the initial state of the population
#    pop_ids = collect(keys(species.pop))
#
#    @test pop_ids == collect(1:10)
#
#    pop_indivs = collect(values(species.pop))
#    genotypes = [indiv.geno for indiv in pop_indivs]
#
#    size_reporter = CohortMetricReporter(metric = GenotypeSize())
#    size_report = size_reporter(gen, species_id, "Population", genotypes)
#    @test size_report.gen == 1
#    @test size_report.species_id == species_id
#    @test size_report.cohort == "Population"
#    @test size_report.metric == "GenotypeSize"
#    @test size_report.stat_features.sum == 100.0
#    @test size_report.stat_features.mean == 10.0
#    @test size_report.stat_features.minimum == 10.0
#    @test size_report.stat_features.maximum == 10.0
#
#    sum_reporter = CohortMetricReporter(metric = GenotypeSum())
#    sum_report = sum_reporter(gen, species_id, "Population", genotypes)
#    @test sum_report.gen == 1
#    @test sum_report.species_id == species_id
#    @test sum_report.cohort == "Population"
#    @test sum_report.metric == "GenotypeSum"
#    @test sum_report.stat_features.sum == 550.0
#    @test sum_report.stat_features.mean == 55.0
#    @test sum_report.stat_features.minimum == 55.0
#    @test sum_report.stat_features.maximum == 55.0
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
    n_parents::Int = 2,
    species_id1::String = "a",
    species_id2::String = "b",
    interaction_id::String = "NumbersGame{Sum}",
    default_vector::Vector{Float64} = fill(0.0, 10),
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
                pheno_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(),
                replacer = GenerationalReplacer(),
                selector = FitnessProportionateSelector(n_parents = n_parents),
                recombiner = CloneRecombiner(),
                mutators = [NoiseInjectionMutator(noise_std = 0.1)],
            ),
            species_id2 => BasicSpeciesCreator(
                id = species_id2,
                n_pop = n_pop,
                geno_creator = BasicVectorGenotypeCreator(default_vector = default_vector),
                pheno_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(),
                replacer = GenerationalReplacer(),
                selector = FitnessProportionateSelector(n_parents = n_parents),
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
        reporters = [BasicReporter(metric = AllSpeciesFitness())],
        archiver = BasicArchiver(),
    )
    return eco_creator

end

eco_creator = dummy_eco_creator()

eco = evolve!(eco_creator, n_gen=10)
@test length(eco.species[species_id1].pop) == n_pop

end

end