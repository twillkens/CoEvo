export DensityClassificationTaskConfiguration, get_ecosystem_creator, create_simulator, create_reproducers
export create_learner_reproducer, create_test_reproducer

using ...Domains.DensityClassification: DensityClassificationDomain
using ...Selectors.Identity: IdentitySelector
using ...Phenotypes.Vectors: CloneVectorPhenotypeCreator
using ...Mutators.Vectors: PerBitMutator
using ...Performers.Cache: CachePerformer
using ...Genotypes.Vectors: DummyNGGenotypeCreator
using ...Ecosystems.MaxSolve 
using ....Abstract
using ....Interfaces
using ...Evaluators.ScalarFitness: ScalarFitnessEvaluator
using ...Selectors.Tournament: TournamentSelector
using ...Selectors.FitnessProportionate: FitnessProportionateSelector
using ...Genotypes.Vectors
using ...Individuals.Basic
using ...Phenotypes.Defaults
using ...Recombiners.Clone
using ...Counters.Basic: BasicCounter
using ...Ecosystems.Simple: SimpleEcosystemCreator
using ...Simulators.Basic: BasicSimulator
using ...Interactions.Basic: BasicInteraction
using ...Environments.Stateless: StatelessEnvironmentCreator
using ...Domains.NumbersGame: NumbersGameDomain
using ...MatchMakers.AllVersusAll: AllVersusAllMatchMaker
using ...Reproducers.Basic: BasicReproducer
using ...Jobs.Simple: SimpleJobCreator
using ...Performers.Basic: BasicPerformer
using ...Performers.Cache: CachePerformer
using ...Genotypes.Vectors: DCTRuleCreator, DCTInitialConditionCreator
using ...Phenotypes.Vectors

Base.@kwdef struct DensityClassificationTaskConfiguration <: Configuration
    # Experiment parameters
    id::Int = 1
    seed::Int = 42
    n_workers::Int = 1
    n_generations::Int = 5
    n_timesteps::Int = 320
    n_validation_initial_conditions::Int = 10_000

    # Learner population parameters
    n_learner_population::Int = 20
    n_learner_children::Int = 20
    learner_recombiner::String = "clone"
    rule_length::Int = 128
    learner_flip_chance::Float64 = 0.02

    # Test population parameters
    n_test_population::Int = 20
    n_test_children::Int = 20
    test_recombiner::String = "clone"
    initial_condition_length::Int = 149
    test_flip_chance::Float64 = 0.05

    # MaxSolve parameters
    algorithm::String = "standard"
    max_learner_archive_size::Int = 10
end

function get_ecosystem_creator(config::DensityClassificationTaskConfiguration)
    ecosystem_creator = MaxSolveEcosystemCreator(
        id = config.id,
        n_learner_population = config.n_learner_population,
        n_learner_children = config.n_learner_children,
        n_test_population = config.n_test_population,
        n_test_children = config.n_test_children,
        algorithm = config.algorithm,
        max_learner_archive_size = config.max_learner_archive_size,
    )
    return ecosystem_creator
end


function create_simulator(config::DensityClassificationTaskConfiguration) 
    domain = DensityClassificationDomain()
    interaction = BasicInteraction(
        id = "A",
        environment_creator = StatelessEnvironmentCreator(domain = domain),
        species_ids = ["L", "T"],
    )
    simulator = BasicSimulator(
        interactions = [interaction],
        matchmaker = AllVersusAllMatchMaker(),
        job_creator = SimpleJobCreator(n_workers = config.n_workers),
        performer = CachePerformer(n_workers = config.n_workers),
    )
    return simulator
end

using ...Recombiners.NPointCrossover: NPointCrossoverRecombiner


RECOMBINERS = Dict(
    "clone" => CloneRecombiner(),
    "one_point_crossover" => NPointCrossoverRecombiner(n_points = 1),
)

function create_learner_reproducer(config::DensityClassificationTaskConfiguration)
    reproducer = BasicReproducer(
        id = "L",
        genotype_creator = DCTRuleCreator(config.rule_length),
        phenotype_creator = CloneVectorPhenotypeCreator(),
        individual_creator = BasicIndividualCreator(),
        species_creator = BasicSpeciesCreator("A", 1, 1, 1, 1),
        selector = IdentitySelector(),
        recombiner = RECOMBINERS[config.learner_recombiner],
        mutator = PerBitMutator(flip_chance = config.learner_flip_chance)
    )
    return reproducer
end

function create_test_reproducer(config::DensityClassificationTaskConfiguration)
    reproducer = BasicReproducer(
        id = "T",
        genotype_creator = DCTInitialConditionCreator(config.initial_condition_length),
        phenotype_creator = CloneVectorPhenotypeCreator(),
        individual_creator = BasicIndividualCreator(),
        species_creator = BasicSpeciesCreator("A", 1, 1, 1, 1),
        selector = IdentitySelector(),
        recombiner = RECOMBINERS[config.test_recombiner],
        mutator = PerBitMutator(flip_chance = config.test_flip_chance, use_symmetry = false)
    )
    return reproducer
end

function create_reproducers(config::DensityClassificationTaskConfiguration)
        learner_reproducer = create_learner_reproducer(config)
        test_reproducer = create_test_reproducer(config)
    return [learner_reproducer, test_reproducer]
end

function create_evaluators(::DensityClassificationTaskConfiguration)
    evaluator = NullEvaluator()
    return [evaluator]
end