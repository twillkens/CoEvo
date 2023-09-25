using StableRNGs: StableRNG
using DataStructures: OrderedDict
using Test

include("../src/CoEvo.jl")
using .CoEvo
using .CoEvo.Ecosystems.Jobs.Domains.Problems.NumbersGame: NumbersGameProblem, interact
using .CoEvo.Ecosystems.Observations: OutcomeObservationConfiguration
using .CoEvo.Ecosystems.Species.Reporters: CohortMetricReporter
using .CoEvo.Utilities.Metrics: GenotypeSum, GenotypeSize, EvaluationFitness
using .CoEvo.Utilities.Counters: Counter

@testset "NumbersGameProblem with Gradient" begin
    problem = NumbersGameProblem(:Gradient)
    obscfg = OutcomeObservationConfiguration()  # Update this as per the new structure, if necessary

    phenoA = [4]  # Vector representation
    phenoB = [5]
    
    observation = interact(problem, "Gradient", obscfg, [1, 2], phenoA, phenoB)  # Replace "domain_id" with the correct domain ID
    outcome_set = observation.outcome_set
    
    @test observation.outcome_set[1] == 0.0  # Assuming the first value is for A
    @test observation.outcome_set[2] == 1.0  # Assuming the second value is for B

    Sₐ = [[1], [2], [3]]  # Vector representation for each phenotype
    Sᵦ = [[6], [7], [8]]

    fitnessA = 0
    for other in Sₐ
        observation = interact(problem, "Gradient", obscfg, [1, 3], phenoA, other)  # Replace 3 with the correct ID for 'other'
        fitnessA += observation.outcome_set[1] == 1.0 ? 1 : 0
    end

    @test fitnessA == 3

    fitnessB = 0
    for other in Sᵦ
        observation = interact(problem, "Gradient", obscfg, [2, 4], phenoB, other)  # Replace 4 with the correct ID for 'other'
        fitnessB += observation.outcome_set[1] == 1.0 ? 1 : 0
    end

    @test fitnessB == 0
end

@testset "NumbersGameProblem with Focusing" begin
    problem = NumbersGameProblem(:Focusing)
    obscfg = OutcomeObservationConfiguration() 

    phenoA = [4, 16]
    phenoB = [5, 14]
    
    observation = interact(problem, "Focusing", obscfg, [1, 2], phenoA, phenoB)
    @test observation.outcome_set[1] == 1.0

    phenoB = [5, 16]
    observation = interact(problem, "Focusing", obscfg, [1, 2], phenoA, phenoB)
    @test observation.outcome_set[1] == 0.0

    phenoA = [5, 16, 8]
    phenoB = [4, 16, 6]
    observation = interact(problem, "Focusing", obscfg, [1, 2], phenoA, phenoB)
    @test observation.outcome_set[1] == 1.0
end

@testset "NumbersGameProblem with Relativism" begin
    problem = NumbersGameProblem(:Relativism)
    obscfg = OutcomeObservationConfiguration()

    a = [1, 6]
    b = [4, 5]
    c = [2, 4]

    observation = interact(problem, "Relativism", obscfg, [1, 2], a, b)
    @test observation.outcome_set[1] == 1.0

    observation = interact(problem, "Relativism", obscfg, [2, 3], b, c)
    @test observation.outcome_set[1] == 1.0

    observation = interact(problem, "Relativism", obscfg, [3, 1], c, a)
    @test observation.outcome_set[1] == 1.0
end


@testset "BasicSpeciesConfiguration" begin
    gen = 1
    rng = StableRNG(42)
    indiv_id_counter = Counter()
    gene_id_counter = Counter()
    species_id = "A"
    n_pop = 10

    default_vector = collect(1:10)

    # Define species configuration similar to spawner
    species_cfg = BasicSpeciesConfiguration(
        id = species_id,
        n_pop = n_pop,
        geno_cfg = VectorGenotypeConfiguration{Float64}(
            default_vector = default_vector
        ),
        pheno_cfg = DefaultPhenotypeConfiguration(),
        indiv_cfg = AsexualIndividualConfiguration(),
        eval_cfg = ScalarFitnessEvaluationConfiguration(),
        replacer = GenerationalReplacer(),
        selector = FitnessProportionateSelector(n_parents = 2),
        recombiner = CloneRecombiner(),
        mutators = [DefaultMutator()],
        reporters = Reporter[],
    )

    # Instantiate the species using the species configuration
    # Assuming there's a way to create initial population from species config
    species = species_cfg(rng, indiv_id_counter, gene_id_counter) 

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
