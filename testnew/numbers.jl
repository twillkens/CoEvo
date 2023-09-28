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

using .CoEvo.Ecosystems.Species: Species
using .CoEvo.Ecosystems.Jobs.Interactions.Domains.NumbersGame: NumbersGame
using .CoEvo.Ecosystems.Jobs.Interactions.Observers.Abstract: Observer
using .NumbersGame: NumbersGameMetric, create_domain, next!, get_outcome_set, act, refresh!
# Problem domains and supporting utilities

using .CoEvo.Ecosystems.Utilities.Counters: Counter
using .NumbersGame: NumbersGameDomainCreator
using .NumbersGame: Sum, Gradient, Focusing, Relativism, Control
using .Species.Reporters: BasicSpeciesReporter
using .Species.Individuals.Genotypes.Vectors: BasicVectorGenotypeCreator
using .Species.Individuals.Phenotypes.Defaults: DefaultPhenotype, DefaultPhenotypeCreator
using .Species.Individuals.Phenotypes: BasicVectorPhenotype
using .Species.Individuals: BasicIndividual, BasicIndividualCreator


using .Species.Reporters.Metrics: GenotypeSum, GenotypeSize, EvaluationFitness
using .CoEvo.Ecosystems: get_outcomes, evolve!
using .CoEvo.Ecosystems.Abstract: Metric

"""
    NumbersGameProblem with Gradient

Test the `NumbersGameProblem` domain using the `Gradient` strategy. This set
confirms the outcomes when different phenotypes interact within the specified domain.
"""

@testset "NumbersGameProblem with Gradient" begin
    phenoA = BasicVectorPhenotype([4])  # Vector representation
    phenoB = BasicVectorPhenotype([5])
    domain_creator = NumbersGameDomainCreator("test", Gradient(), [phenoA, phenoB])
    domain = create_domain("test", domain_creator)

    #next!(domain)
    println("hi")
    outcome_set = get_outcome_set(domain)
    println("there")
    
    @test outcome_set[1] == 0.0  # Assuming the first value is for A
    @test outcome_set[2] == 1.0  # Assuming the second value is for B

    Sₐ = [BasicVectorPhenotype(x) for x in [[1], [2], [3]]]  # Vector representation for each phenotype
    Sᵦ =  [BasicVectorPhenotype(x) for x in [[6], [7], [8]]]

    fitnessA = 0
    for other in Sₐ
        domain.entities = [phenoA, other]
        #next!(domain)
        outcome_set = get_outcome_set(domain)
        fitnessA += outcome_set[1] == 1.0 ? 1 : 0
    end

    @test fitnessA == 3

    fitnessB = 0
    for other in Sᵦ
        domain.entities = [phenoB, other]
        outcome_set = get_outcome_set(domain)
        #next!(domain)
        fitnessB += outcome_set[1] == 1.0 ? 1 : 0
    end

    @test fitnessB == 0
end

@testset "NumbersGameProblem with Focusing" begin
    phenoA = BasicVectorPhenotype([4, 16])  # Vector representation
    phenoB = BasicVectorPhenotype([5, 14])
    domain_creator = NumbersGameDomainCreator("test_focusing", Focusing(), [phenoA, phenoB])
    domain = create_domain("test_focusing", domain_creator)

    outcome_set = get_outcome_set(domain)
    @test outcome_set[1] == 1.0

    phenoB = BasicVectorPhenotype([5, 16])
    domain.entities = [phenoA, phenoB]
    outcome_set = get_outcome_set(domain)
    @test outcome_set[1] == 0.0

    phenoA = BasicVectorPhenotype([5, 16, 8])
    phenoB = BasicVectorPhenotype([4, 16, 6])
    domain.entities = [phenoA, phenoB]
    outcome_set = get_outcome_set(domain)
    @test outcome_set[1] == 1.0
end


@testset "NumbersGameProblem with Relativism" begin
    a = BasicVectorPhenotype([1, 6])
    b = BasicVectorPhenotype([4, 5])
    c = BasicVectorPhenotype([2, 4])

    domain_creator = NumbersGameDomainCreator("test_relativism", Relativism(), [a, b])
    domain = create_domain("test_relativism", domain_creator)

    outcome_set = get_outcome_set(domain)
    @test outcome_set[1] == 1.0

    domain.entities = [b, c]
    outcome_set = get_outcome_set(domain)
    @test outcome_set[1] == 1.0

    domain.entities = [c, a]
    outcome_set = get_outcome_set(domain)
    @test outcome_set[1] == 1.0
end

#"""
#    NumbersGameProblem with Focusing
#
#Test the `NumbersGameProblem` domain using the `Focusing` strategy. Evaluates the
#responses of various phenotypic interactions.
#"""
#
#@testset "NumbersGameProblem with Focusing" begin
#    problem = NumbersGameProblem(:Focusing)
#    obscreator = OutcomeObservationCreator() 
#
#    phenoA = [4, 16]
#    phenoB = [5, 14]
#    
#    observation = interact(problem, "Focusing", obscreator, [1, 2], phenoA, phenoB)
#    @test observation.outcome_set[1] == 1.0
#
#    phenoB = [5, 16]
#    observation = interact(problem, "Focusing", obscreator, [1, 2], phenoA, phenoB)
#    @test observation.outcome_set[1] == 0.0
#
#    phenoA = [5, 16, 8]
#    phenoB = [4, 16, 6]
#    observation = interact(problem, "Focusing", obscreator, [1, 2], phenoA, phenoB)
#    @test observation.outcome_set[1] == 1.0
#end
#
#"""
#    NumbersGameProblem with Relativism
#
#Test the `NumbersGameProblem` domain using the `Relativism` strategy. 
#This checks the outcomes for a set of phenotype interactions under relativistic scenarios.
#"""
#
#@testset "NumbersGameProblem with Relativism" begin
#    problem = NumbersGameProblem(:Relativism)
#    obscreator = OutcomeObservationCreator()
#
#    a = [1, 6]
#    b = [4, 5]
#    c = [2, 4]
#
#    observation = interact(problem, "Relativism", obscreator, [1, 2], a, b)
#    @test observation.outcome_set[1] == 1.0
#
#    observation = interact(problem, "Relativism", obscreator, [2, 3], b, c)
#    @test observation.outcome_set[1] == 1.0
#
#    observation = interact(problem, "Relativism", obscreator, [3, 1], c, a)
#    @test observation.outcome_set[1] == 1.0
#end
#
#"""
#    BasicSpeciesCreator Test
#
#Test the configuration and initialization of species with `BasicSpeciesCreator`.
#This confirms the proper setup and initial state of species.
#"""
#
#@testset "BasicSpeciesCreator" begin
#    gen = 1
#    rng = StableRNG(42)
#    indiv_id_counter = Counter()
#    gene_id_counter = Counter()
#    species_id = "A"
#    n_pop = 10
#
#    default_vector = collect(1:10)
#
#    # Define species configuration similar to spawner
#    species_creator = BasicSpeciesCreator(
#        id = species_id,
#        n_pop = n_pop,
#        geno_creator = BasicVectorGenotypeCreator{Float64}(
#            default_vector = default_vector
#        ),
#        pheno_creator = DefaultPhenotypeCreator(),
#        indiv_creator = AsexualIndividualCreator(),
#        eval_creator = ScalarFitnessEvaluationCreator(),
#        replacer = GenerationalReplacer(),
#        selector = FitnessProportionateSelector(n_parents = 2),
#        recombiner = CloneRecombiner(),
#        mutators = [DefaultMutator()],
#        reporters = Reporter[],
#    )
#
#    # Instantiate the species using the species configuration
#    # Assuming there's a way to create initial population from species config
#    species = species_creator(rng, indiv_id_counter, gene_id_counter) 
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
#end
#
#"""
#    `evolve!` Functionality Test
#
#Tests the primary evolutionary function `evolve!` within a co-evolutionary context.
#Ensures the successful progression of generations and expected state changes.
#"""
#
#@testset "evolve!" begin
#
#function dummy_eco_creator(;
#    id::String = "test",
#    trial::Int = 1,
#    rng::AbstractRNG = StableRNG(42),
#    n_pop::Int = 2,
#    n_parents::Int = 2,
#    species_id1::String = "a",
#    species_id2::String = "b",
#    domain_id::String = "NumbersGame{Sum}",
#    default_vector::Vector{Float64} = fill(0.0, 10),
#)
#    eco_creator = CoevolutionaryEcosystemCreator(
#        id = id,
#        trial = trial,
#        rng = rng,
#        species_creators = OrderedDict(
#            species_id1 => BasicSpeciesCreator(
#                id = species_id1,
#                n_pop = n_pop,
#                geno_creator = BasicVectorGenotypeCreator(default_vector = default_vector),
#                pheno_creator = DefaultPhenotypeCreator(),
#                indiv_creator = AsexualIndividualCreator(),
#                eval_creator = ScalarFitnessEvaluationCreator(),
#                replacer = GenerationalReplacer(),
#                selector = FitnessProportionateSelector(n_parents = n_parents),
#                recombiner = CloneRecombiner(),
#                mutators = [DefaultMutator()],
#                reporters = [CohortMetricReporter(metric = EvaluationFitness())],
#            ),
#            species_id2 => BasicSpeciesCreator(
#                id = species_id2,
#                n_pop = n_pop,
#                geno_creator = BasicVectorGenotypeCreator(default_vector = default_vector),
#                pheno_creator = DefaultPhenotypeCreator(),
#                indiv_creator = AsexualIndividualCreator(),
#                eval_creator = ScalarFitnessEvaluationCreator(),
#                replacer = GenerationalReplacer(),
#                selector = FitnessProportionateSelector(n_parents = n_parents),
#                recombiner = CloneRecombiner(),
#                mutators = [DefaultMutator()],
#                reporters = [CohortMetricReporter(metric = EvaluationFitness())],
#            ),
#        ),
#        job_creator = InteractionJobCreator(
#            n_workers = 1,
#            dom_creators = OrderedDict(
#                domain_id => InteractiveDomainCreator(
#                    id = domain_id,
#                    problem = NumbersGameProblem(:Sum),
#                    species_ids = [species_id1, species_id2],
#                    obs_creator = OutcomeObservationCreator(),
#                    matchmaker = AllvsAllMatchMaker(type = :plus),
#                    reporters = Reporter[]
#                ),
#            ),
#        ),
#        archiver = DefaultArchiver(),
#        indiv_id_counter = Counter(),
#        gene_id_counter = Counter(),
#        runtime_reporter = RuntimeReporter(),
#    )
#
#    eco = evolve!(eco_creator, n_gen=10)
#    @test length(eco.species[species_id1].pop) == n_pop
#end
#
#end

end