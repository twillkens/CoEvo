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

# Problem domains and supporting utilities
using .CoEvo.Ecosystems.Jobs.Domains.Problems.NumbersGame: NumbersGameProblem, interact
using .CoEvo.Ecosystems.Observations: OutcomeObservationCreator
using .CoEvo.Ecosystems.Species.Reporters: CohortMetricReporter
using .CoEvo.Ecosystems.Species.Substrates: BasicVectorGenotypeCreator
using .CoEvo.Ecosystems.Species.Substrates: DefaultPhenotypeCreator, DefaultPhenotype
using .CoEvo.Ecosystems.Species.Substrates.Defaults: DefaultPhenotype
using .CoEvo.Utilities.Metrics: GenotypeSum, GenotypeSize, EvaluationFitness
using .CoEvo.Utilities.Counters: Counter

"""
    NumbersGameProblem with Gradient

Test the `NumbersGameProblem` domain using the `Gradient` strategy. This set
confirms the outcomes when different phenotypes interact within the specified domain.
"""

@testset "NumbersGameProblem with Gradient" begin
    problem = NumbersGameProblem(:Gradient)
    obscreator = OutcomeObservationCreator()  # Update this as per the new structure, if necessary

    phenoA = DefaultPhenotype([4])  # Vector representation
    phenoB = DefaultPhenotype([5])
    
    observation = interact(problem, "Gradient", obscreator, [1, 2], phenoA, phenoB)  # Replace "domain_id" with the correct domain ID
    outcome_set = observation.outcome_set
    
    @test observation.outcome_set[1] == 0.0  # Assuming the first value is for A
    @test observation.outcome_set[2] == 1.0  # Assuming the second value is for B

    Sₐ = [DefaultPhenotype(x) for x in [[1], [2], [3]]]  # Vector representation for each phenotype
    Sᵦ =  [DefaultPhenotype(x) for x in [[6], [7], [8]]]

    fitnessA = 0
    for other in Sₐ
        observation = interact(problem, "Gradient", obscreator, [1, 3], phenoA, other)  # Replace 3 with the correct ID for 'other'
        fitnessA += observation.outcome_set[1] == 1.0 ? 1 : 0
    end

    @test fitnessA == 3

    fitnessB = 0
    for other in Sᵦ
        observation = interact(problem, "Gradient", obscreator, [2, 4], phenoB, other)  # Replace 4 with the correct ID for 'other'
        fitnessB += observation.outcome_set[1] == 1.0 ? 1 : 0
    end

    @test fitnessB == 0
end

"""
    NumbersGameProblem with Focusing

Test the `NumbersGameProblem` domain using the `Focusing` strategy. Evaluates the
responses of various phenotypic interactions.
"""

@testset "NumbersGameProblem with Focusing" begin
    problem = NumbersGameProblem(:Focusing)
    obscreator = OutcomeObservationCreator() 

    phenoA = [4, 16]
    phenoB = [5, 14]
    
    observation = interact(problem, "Focusing", obscreator, [1, 2], phenoA, phenoB)
    @test observation.outcome_set[1] == 1.0

    phenoB = [5, 16]
    observation = interact(problem, "Focusing", obscreator, [1, 2], phenoA, phenoB)
    @test observation.outcome_set[1] == 0.0

    phenoA = [5, 16, 8]
    phenoB = [4, 16, 6]
    observation = interact(problem, "Focusing", obscreator, [1, 2], phenoA, phenoB)
    @test observation.outcome_set[1] == 1.0
end

"""
    NumbersGameProblem with Relativism

Test the `NumbersGameProblem` domain using the `Relativism` strategy. 
This checks the outcomes for a set of phenotype interactions under relativistic scenarios.
"""

@testset "NumbersGameProblem with Relativism" begin
    problem = NumbersGameProblem(:Relativism)
    obscreator = OutcomeObservationCreator()

    a = [1, 6]
    b = [4, 5]
    c = [2, 4]

    observation = interact(problem, "Relativism", obscreator, [1, 2], a, b)
    @test observation.outcome_set[1] == 1.0

    observation = interact(problem, "Relativism", obscreator, [2, 3], b, c)
    @test observation.outcome_set[1] == 1.0

    observation = interact(problem, "Relativism", obscreator, [3, 1], c, a)
    @test observation.outcome_set[1] == 1.0
end

"""
    BasicSpeciesCreator Test

Test the configuration and initialization of species with `BasicSpeciesCreator`.
This confirms the proper setup and initial state of species.
"""

@testset "BasicSpeciesCreator" begin
    gen = 1
    rng = StableRNG(42)
    indiv_id_counter = Counter()
    gene_id_counter = Counter()
    species_id = "A"
    n_pop = 10

    default_vector = collect(1:10)

    # Define species configuration similar to spawner
    species_creator = BasicSpeciesCreator(
        id = species_id,
        n_pop = n_pop,
        geno_creator = BasicVectorGenotypeCreator{Float64}(
            default_vector = default_vector
        ),
        pheno_creator = DefaultPhenotypeCreator(),
        indiv_creator = AsexualIndividualCreator(),
        eval_creator = ScalarFitnessEvaluationCreator(),
        replacer = GenerationalReplacer(),
        selector = FitnessProportionateSelector(n_parents = 2),
        recombiner = CloneRecombiner(),
        mutators = [DefaultMutator()],
        reporters = Reporter[],
    )

    # Instantiate the species using the species configuration
    # Assuming there's a way to create initial population from species config
    species = species_creator(rng, indiv_id_counter, gene_id_counter) 

    # Test the initial state of the population
    pop_ids = collect(keys(species.pop))

    @test pop_ids == collect(1:10)

    pop_indivs = collect(values(species.pop))
    genotypes = [indiv.geno for indiv in pop_indivs]

    size_reporter = CohortMetricReporter(metric = GenotypeSize())
    size_report = size_reporter(gen, species_id, "Population", genotypes)
    @test size_report.gen == 1
    @test size_report.species_id == species_id
    @test size_report.cohort == "Population"
    @test size_report.metric == "GenotypeSize"
    @test size_report.stat_features.sum == 100.0
    @test size_report.stat_features.mean == 10.0
    @test size_report.stat_features.minimum == 10.0
    @test size_report.stat_features.maximum == 10.0

    sum_reporter = CohortMetricReporter(metric = GenotypeSum())
    sum_report = sum_reporter(gen, species_id, "Population", genotypes)
    @test sum_report.gen == 1
    @test sum_report.species_id == species_id
    @test sum_report.cohort == "Population"
    @test sum_report.metric == "GenotypeSum"
    @test sum_report.stat_features.sum == 550.0
    @test sum_report.stat_features.mean == 55.0
    @test sum_report.stat_features.minimum == 55.0
    @test sum_report.stat_features.maximum == 55.0
end

"""
    `evolve!` Functionality Test

Tests the primary evolutionary function `evolve!` within a co-evolutionary context.
Ensures the successful progression of generations and expected state changes.
"""

@testset "evolve!" begin

function dummy_eco_creator(;
    id::String = "test",
    trial::Int = 1,
    rng::AbstractRNG = StableRNG(42),
    n_pop::Int = 2,
    n_parents::Int = 2,
    species_id1::String = "a",
    species_id2::String = "b",
    domain_id::String = "NumbersGame{Sum}",
    default_vector::Vector{Float64} = fill(0.0, 10),
)
    eco_creator = CoevolutionaryEcosystemCreator(
        id = id,
        trial = trial,
        rng = rng,
        species_creators = OrderedDict(
            species_id1 => BasicSpeciesCreator(
                id = species_id1,
                n_pop = n_pop,
                geno_creator = BasicVectorGenotypeCreator(default_vector = default_vector),
                pheno_creator = DefaultPhenotypeCreator(),
                indiv_creator = AsexualIndividualCreator(),
                eval_creator = ScalarFitnessEvaluationCreator(),
                replacer = GenerationalReplacer(),
                selector = FitnessProportionateSelector(n_parents = n_parents),
                recombiner = CloneRecombiner(),
                mutators = [DefaultMutator()],
                reporters = [CohortMetricReporter(metric = EvaluationFitness())],
            ),
            species_id2 => BasicSpeciesCreator(
                id = species_id2,
                n_pop = n_pop,
                geno_creator = BasicVectorGenotypeCreator(default_vector = default_vector),
                pheno_creator = DefaultPhenotypeCreator(),
                indiv_creator = AsexualIndividualCreator(),
                eval_creator = ScalarFitnessEvaluationCreator(),
                replacer = GenerationalReplacer(),
                selector = FitnessProportionateSelector(n_parents = n_parents),
                recombiner = CloneRecombiner(),
                mutators = [DefaultMutator()],
                reporters = [CohortMetricReporter(metric = EvaluationFitness())],
            ),
        ),
        job_creator = InteractionJobCreator(
            n_workers = 1,
            dom_creators = OrderedDict(
                domain_id => InteractiveDomainCreator(
                    id = domain_id,
                    problem = NumbersGameProblem(:Sum),
                    species_ids = [species_id1, species_id2],
                    obs_creator = OutcomeObservationCreator(),
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                    reporters = Reporter[]
                ),
            ),
        ),
        archiver = DefaultArchiver(),
        indiv_id_counter = Counter(),
        gene_id_counter = Counter(),
        runtime_reporter = RuntimeReporter(),
    )

    eco = evolve!(eco_creator, n_gen=10)
    @test length(eco.species[species_id1].pop) == n_pop
end

end

end