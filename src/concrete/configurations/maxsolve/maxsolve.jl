module MaxSolve

export MaxSolveConfiguration, get_ecosystem_creator, create_reproducer, create_reproducers
export create_simulator, create_evaluator, create_archivers
export create_numbers_game_reproducer, create_numbers_game_simulator
export create_fsm_simulator, create_learner_fsm_reproducer, create_test_fsm_reproducer


import ....Interfaces: create_reproducers, create_simulator, create_evaluators, create_archivers
import ....Interfaces: get_ecosystem_creator
using ...Mutators.Vectors: NumbersGameVectorMutator
using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...Individuals.Basic
using ...Phenotypes.Vectors: NumbersGamePhenotypeCreator
using ...Genotypes.Vectors
using ...Selectors.Identity
using ...Recombiners.Clone
using ...Ecosystems.MaxSolve: MaxSolveEcosystemCreator
using ...Evaluators.Null: NullEvaluator
using ....Abstract

include("imports.jl")

Base.@kwdef struct MaxSolveConfiguration <: Configuration
    # General
    id::Int = 1
    archive_directory::String = "."
    seed::Int = 42
    n_generations::Int = 5
    n_workers::Int = 1

    # Algorithm
    algorithm::String = "control"
    learner_algorithm::String = "control"
    test_algorithm::String = "control"
    n_learner_population::Int = 100
    n_learner_children::Int = 100
    n_test_population::Int = 100
    n_test_children::Int = 100
    max_learner_archive_size::Int = 1_000

    # Problem
    task::String = "numbers_game"
    domain::String = "CompareOnAll"

    # NG specific
    n_dimensions::Int = 5
    init_range::Tuple{Float64, Float64} = (0.0, 0.1)
    use_delta::Bool = false
    delta::Float64 = 0.25
    n_mutations::Int = 1
    min_mutation::Float64 = -0.15
    max_mutation::Float64 = 0.1
    mutation_granularity::Float64 = 0.01

    # DCT specific
    learner_flip_chance::Float64 = 0.02
    test_flip_chance::Float64 = 0.05

    # FSM specific
    checkpoint_interval::Int = 100
end

function get_ecosystem_creator(config::MaxSolveConfiguration)
    ecosystem_creator = MaxSolveEcosystemCreator(
        id = config.id,
        learner_algorithm = config.learner_algorithm,
        test_algorithm = config.test_algorithm,
        n_learner_population = config.n_learner_population,
        n_learner_children = config.n_learner_children,
        n_test_population = config.n_test_population,
        n_test_children = config.n_test_children,
        max_learner_archive_size = config.max_learner_archive_size,
    )
    return ecosystem_creator
end

dummy_species_creator() = BasicSpeciesCreator("A", 1, 1, 1, 1)

function create_numbers_game_reproducer(config::MaxSolveConfiguration, species_id::String)
    reproducer = BasicReproducer(
        id = species_id,
        genotype_creator = NumbersGameVectorGenotypeCreator(
            length = config.n_dimensions,
            init_range = config.init_range,
            mutation_granularity = config.mutation_granularity
        ),
        phenotype_creator = NumbersGamePhenotypeCreator(
            use_delta = config.use_delta, delta = config.delta
        ),
        individual_creator = BasicIndividualCreator(),
        species_creator = dummy_species_creator(),
        selector = IdentitySelector(),
        recombiner = CloneRecombiner(),
        mutator = NumbersGameVectorMutator(
            config.n_mutations, 
            config.min_mutation, 
            config.max_mutation, 
            config.mutation_granularity
        ),
    )
    return reproducer
end

function create_reproducers(config::MaxSolveConfiguration)
    if config.task == "numbers_game"
        learner_reproducer = create_numbers_game_reproducer(config, "L")
        test_reproducer = create_numbers_game_reproducer(config, "T")
    elseif config.task == "dct"
        learner_reproducer = create_learner_dct_reproducer(config)
        test_reproducer = create_test_dct_reproducer(config)
    elseif config.task == "fsm"
        learner_reproducer = create_learner_fsm_reproducer(config)
        test_reproducer = create_test_fsm_reproducer(config)
    else
        error("Invalid task: $(config.task)")
    end
    return [learner_reproducer, test_reproducer]
end


function create_numbers_game_simulator(config::MaxSolveConfiguration) 
    simulator = BasicSimulator(
        interactions = [
            BasicInteraction(
                id = "A",
                environment_creator = StatelessEnvironmentCreator(
                    domain = NumbersGameDomain(config.domain)
                ),
                species_ids = ["L", "T"],
            )
        ],
        matchmaker = AllVersusAllMatchMaker(),
        job_creator = SimpleJobCreator(n_workers = config.n_workers),
        performer = BasicPerformer(n_workers = config.n_workers),
    )
    return simulator
end

function create_simulator(config::MaxSolveConfiguration) 
    if config.task == "numbers_game"
        simulator = create_numbers_game_simulator(config)
    elseif config.task == "dct"
        simulator = create_dct_simulator(config)
    elseif config.task == "fsm"
        simulator = create_fsm_simulator(config)
    else
        error("Invalid task: $(config.task)")
    end
end

function create_evaluators(::MaxSolveConfiguration)
    evaluator = NullEvaluator()
    return [evaluator]
end

include("numbers_game_archive.jl")
include("dct_archive.jl")
include("fsm_archive.jl")

function create_archivers(config::MaxSolveConfiguration)
    if config.task == "numbers_game"
        archivers = [NumbersGameArchiver(config)]
    elseif config.task == "dct"
        archivers = [DensityClassificationArchiver(config)]
    elseif config.task == "fsm"
        archivers = [FSMArchiver(config)]
    else
        error("Invalid task: $(config.task)")
    end
    return archivers
end


#------------------------------- DCT
using ...Environments.ElementaryCellularAutomata: ElementaryCellularAutomataEnvironmentCreator
#using ...Environments.ECAOptimized: ElementaryCellularAutomataEnvironmentCreator
using ...Domains.DensityClassification: DensityClassificationDomain
using ...Selectors.Identity: IdentitySelector
using ...Phenotypes.Vectors: CloneVectorPhenotypeCreator
using ...Mutators.Vectors: PerBitMutator
using ...Performers.Cache: CachePerformer

function create_dct_simulator(config::MaxSolveConfiguration) 
    simulator = BasicSimulator(
        interactions = [
            BasicInteraction(
                id = "A",
                environment_creator = StatelessEnvironmentCreator(
                    domain = DensityClassificationDomain()
                ),
                species_ids = ["L", "T"],
            )
        ],
        matchmaker = AllVersusAllMatchMaker(),
        job_creator = SimpleJobCreator(n_workers = config.n_workers),
        performer = CachePerformer(n_workers = config.n_workers),
    )
    return simulator
end

using ...Recombiners.NPointCrossover: NPointCrossoverRecombiner

function create_learner_dct_reproducer(config::MaxSolveConfiguration)
    reproducer = BasicReproducer(
        id = "L",
        genotype_creator = DCTRuleCreator(),
        phenotype_creator = CloneVectorPhenotypeCreator(),
        individual_creator = BasicIndividualCreator(),
        species_creator = dummy_species_creator(),
        selector = IdentitySelector(),
        recombiner = NPointCrossoverRecombiner(n_points = 1),
        #recombiner = CloneRecombiner(),
        mutator = PerBitMutator(flip_chance = config.learner_flip_chance)
    )
    return reproducer
end

function create_test_dct_reproducer(config::MaxSolveConfiguration)
    reproducer = BasicReproducer(
        id = "T",
        genotype_creator = DCTInitialConditionCreator(),
        phenotype_creator = CloneVectorPhenotypeCreator(),
        individual_creator = BasicIndividualCreator(),
        species_creator = dummy_species_creator(),
        selector = IdentitySelector(),
        recombiner = NPointCrossoverRecombiner(n_points = 1),
        #recombiner = CloneRecombiner(),
        mutator = PerBitMutator(flip_chance = config.test_flip_chance, use_symmetry = true)
        #mutator = PerBitMutator(flip_chance = config.learner_flip_chance)
    )
    return reproducer
end

#------------------------------- FSM
#using ...Environments.ElementaryCellularAutomata: ElementaryCellularAutomataEnvironmentCreator
using ...Environments.LinguisticPredictionGame: LinguisticPredictionGameEnvironmentCreator
using ...Domains.PredictionGame: PredictionGameDomain
using ...Phenotypes.Defaults: DefaultPhenotypeCreator
using ...Genotypes.FiniteStateMachines: FiniteStateMachineGenotypeCreator
using ...Mutators.FiniteStateMachines: FiniteStateMachineMutator

#using ...Environments.ECAOptimized: ElementaryCellularAutomataEnvironmentCreator
#using ...Domains.DensityClassification: DensityClassificationDomain
using ...Selectors.Identity: IdentitySelector
using ...Phenotypes.Vectors: CloneVectorPhenotypeCreator
using ...Mutators.Vectors: PerBitMutator
using ...Performers.Cache: CachePerformer


function create_fsm_simulator(config::MaxSolveConfiguration) 
    domain = PredictionGameDomain(config.domain)
    environment_creator = LinguisticPredictionGameEnvironmentCreator(domain)
    simulator = BasicSimulator(
        interactions = [
            BasicInteraction(
                id = "A",
                environment_creator = environment_creator,
                species_ids = ["L", "T"],
            )
        ],
        matchmaker = AllVersusAllMatchMaker(),
        job_creator = SimpleJobCreator(n_workers = config.n_workers),
        performer = CachePerformer(n_workers = config.n_workers),
    )
    return simulator
end

using ...Recombiners.NPointCrossover: NPointCrossoverRecombiner
using ...Individuals.Modes: ModesIndividualCreator

function create_learner_fsm_reproducer(config::MaxSolveConfiguration)
    reproducer = BasicReproducer(
        id = "L",
        genotype_creator = FiniteStateMachineGenotypeCreator(),
        phenotype_creator = DefaultPhenotypeCreator(),
        individual_creator = ModesIndividualCreator(),
        species_creator = dummy_species_creator(),
        selector = IdentitySelector(),
        recombiner = CloneRecombiner(),
        mutator = FiniteStateMachineMutator(n_changes = 1)
    )
    return reproducer
end

function create_test_fsm_reproducer(config::MaxSolveConfiguration)
    reproducer = BasicReproducer(
        id = "T",
        genotype_creator = FiniteStateMachineGenotypeCreator(),
        phenotype_creator = DefaultPhenotypeCreator(),
        individual_creator = ModesIndividualCreator(),
        species_creator = dummy_species_creator(),
        selector = IdentitySelector(),
        recombiner = CloneRecombiner(),
        mutator = FiniteStateMachineMutator(n_changes = 1)
    )
    return reproducer
end

end
