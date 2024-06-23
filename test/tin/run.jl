using CoEvo.Concrete.Configurations.MaxSolve
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces
using Distributed
using Random

# Number of trials you want to run
const N_TRIALS = 60

# Initialize required number of worker processes
addprocs(N_TRIALS)

@everywhere begin
    using CoEvo.Concrete.Configurations.MaxSolve
    using CoEvo.Concrete.States.Basic
    using CoEvo.Interfaces
    using Random
end

# Define constants for configuration
@everywhere begin
    const N_LEARNER_POP = 100
    const N_LEARNER_CHILDREN = 100
    const N_TEST_POP = 100
    const N_TEST_CHILDREN = 100
    const N_ARCHIVE = 1000
    const N_COO_GENERATIONS = 500
    const N_DCT_GENERATIONS = 200
    const N_FSM_GENERATIONS = 10_000

    Base.@kwdef struct AlgorithmSpecification
        id::Int
        name::String
        learner_algorithm::String
        test_algorithm::String
    end
# Function to run each trial

    function run_ng_easy_trial(spec::AlgorithmSpecification)
        seed = abs(rand(Int))
        Random.seed!(seed)
        archive_path = "data/coo_easy/$(spec.name)/$(spec.id)"
        mkpath(archive_path)
        mkpath("$archive_path/population")

        config = MaxSolveConfiguration(
            # General
            id = spec.id,
            archive_directory = archive_path,
            seed = seed,
            n_generations = N_COO_GENERATIONS,
            n_workers = 1,  # Using 1 worker per trial

            # Algorithm
            algorithm = spec.name,
            learner_algorithm = spec.learner_algorithm,
            test_algorithm = spec.test_algorithm,
            n_learner_population = N_LEARNER_POP, 
            n_learner_children = N_LEARNER_CHILDREN, 
            n_test_population = N_TEST_POP, 
            n_test_children = N_TEST_CHILDREN,
            max_learner_archive_size = N_ARCHIVE,

            # Problem
            task = "numbers_game",
            domain = "coo",
            n_dimensions = 2,
            min_mutation = -0.1,
            max_mutation = 0.1,
            init_range = (0.0, 0.1),
            use_delta = false,
            delta = 0.0,
            mutation_granularity = 0.001
        )

        state = BasicEvolutionaryState(config)
        evolve!(state)
        println("Trial $(spec.id) done")
    end
    
    function run_ng_hard_trial(spec::AlgorithmSpecification)
        seed = abs(rand(Int))
        Random.seed!(seed)
        archive_path = "data/coo_hard/$(spec.name)/$(spec.id)"
        mkpath(archive_path)
        mkpath("$archive_path/population")

        config = MaxSolveConfiguration(
            # General
            id = spec.id,
            archive_directory = archive_path,
            seed = seed,
            n_generations = N_COO_GENERATIONS,
            n_workers = 1,  # Using 1 worker per trial

            # Algorithm
            algorithm = spec.name,
            learner_algorithm = spec.learner_algorithm,
            test_algorithm = spec.test_algorithm,
            n_learner_population = N_LEARNER_POP, 
            n_learner_children = N_LEARNER_CHILDREN, 
            n_test_population = N_TEST_POP, 
            n_test_children = N_TEST_CHILDREN,
            max_learner_archive_size = N_ARCHIVE,

            # Problem
            task = "numbers_game",
            domain = "coo",
            n_dimensions = 5,
            min_mutation = -0.15,
            max_mutation = 0.1,
            init_range = (0.0, 0.1),
            use_delta = false,
            delta = 0.0,
            mutation_granularity = 0.001
        )

        state = BasicEvolutionaryState(config)
        evolve!(state)
        println("Trial $(spec.id) done")
    end

    function run_dct_trial(spec::AlgorithmSpecification)
        seed = abs(rand(Int))
        Random.seed!(seed)
        archive_path = "data/dct/$(spec.name)/$(spec.id)"
        mkpath(archive_path)
        mkpath("$archive_path/population")

        config = MaxSolveConfiguration(
            # General
            id = spec.id,
            archive_directory = archive_path,
            seed = seed,
            n_generations = N_DCT_GENERATIONS,
            n_workers = 1,  # Using 1 worker per trial

            # Algorithm
            algorithm = spec.name,
            learner_algorithm = spec.learner_algorithm,
            test_algorithm = spec.test_algorithm,
            n_learner_population = N_LEARNER_POP, 
            n_learner_children = N_LEARNER_CHILDREN, 
            n_test_population = N_TEST_POP, 
            n_test_children = N_TEST_CHILDREN,
            max_learner_archive_size = N_ARCHIVE,

            # Problem
            task = "dct",
            domain = "n_149",
            learner_flip_chance = 0.02,
            test_flip_chance = 0.05
        )

        state = BasicEvolutionaryState(config)
        evolve!(state)
        println("Trial $(spec.id) done")
    end
    
    function run_fsm_trial(spec::AlgorithmSpecification)
        seed = abs(rand(Int))
        Random.seed!(seed)
        archive_path = "data/fsm/$(spec.name)/$(spec.id)"
        mkpath(archive_path)
        mkpath("$archive_path/population")

        config = MaxSolveConfiguration(
            # General
            id = spec.id,
            archive_directory = "data/fsm/$(spec.name)",
            seed = seed,
            n_generations = N_FSM_GENERATIONS,
            n_workers = 1,  # Using 1 worker per trial

            # Algorithm
            algorithm = spec.name,
            learner_algorithm = spec.learner_algorithm,
            test_algorithm = spec.test_algorithm,
            n_learner_population = N_LEARNER_POP, 
            n_learner_children = N_LEARNER_CHILDREN, 
            n_test_population = N_TEST_POP, 
            n_test_children = N_TEST_CHILDREN,
            max_learner_archive_size = N_ARCHIVE,

            # Problem
            task = "fsm",
            domain = "PredatorPrey",
            n_mutations = 1,
        )

        state = BasicEvolutionaryState(config)
        evolve!(state)
        println("Trial $(spec.id) done")
    end
end

control_specs = [
    AlgorithmSpecification(
        id = i,
        name = "control",
        learner_algorithm = "control",
        test_algorithm = "control"
    ) for i in 1:N_TRIALS
]

roulette_specs = [
    AlgorithmSpecification(
        id = i,
        name = "roulette",
        learner_algorithm = "roulette",
        test_algorithm = "roulette"
    ) for i in 1:N_TRIALS
]

cfs_std_specs = [
    AlgorithmSpecification(
        id = i,
        name = "cfs_std",
        learner_algorithm = "cfs",
        test_algorithm = "standard"
    ) for i in 1:N_TRIALS
]

cfs_adv_specs = [
    AlgorithmSpecification(
        id = i,
        name = "cfs_adv",
        learner_algorithm = "cfs",
        test_algorithm = "advanced"
    ) for i in 1:N_TRIALS
]

doc_std_specs = [
    AlgorithmSpecification(
        id = i,
        name = "doc_std",
        learner_algorithm = "doc",
        test_algorithm = "standard"
    ) for i in 1:N_TRIALS
]

doc_adv_specs = [
    AlgorithmSpecification(
        id = i,
        name = "doc_adv",
        learner_algorithm = "doc",
        test_algorithm = "advanced"
    ) for i in 1:N_TRIALS
]

p_phc_specs = [
    AlgorithmSpecification(
        id = i,
        name = "p_phc",
        learner_algorithm = "p_phc",
        test_algorithm = "p_phc"
    ) for i in 1:N_TRIALS
]

p_phc_p_frs_specs = [
    AlgorithmSpecification(
        id = i,
        name = "p_phc_p_frs",
        learner_algorithm = "p_phc_p_frs",
        test_algorithm = "p_phc_p_frs"
    ) for i in 1:N_TRIALS
]

p_phc_p_uhs_specs = [
    AlgorithmSpecification(
        id = i,
        name = "p_phc_p_uhs",
        learner_algorithm = "p_phc_p_uhs",
        test_algorithm = "p_phc_p_uhs"
    ) for i in 1:N_TRIALS
]

cfs_qmeu_slow_specs = [
    AlgorithmSpecification(
        id = i,
        name = "cfs_qmeu_slow",
        learner_algorithm = "cfs",
        test_algorithm = "qmeu_slow"
    ) for i in 1:N_TRIALS
]

cfs_qmeu_fast_specs = [
    AlgorithmSpecification(
        id = i,
        name = "cfs_qmeu_fast",
        learner_algorithm = "cfs",
        test_algorithm = "qmeu_fast"
    ) for i in 1:N_TRIALS
]

doc_qmeu_slow_specs = [
    AlgorithmSpecification(
        id = i,
        name = "doc_qmeu_slow",
        learner_algorithm = "doc",
        test_algorithm = "qmeu_slow"
    ) for i in 1:N_TRIALS
]

doc_qmeu_fast_specs = [
    AlgorithmSpecification(
        id = i,
        name = "doc_qmeu_fast",
        learner_algorithm = "doc",
        test_algorithm = "qmeu_fast"
    ) for i in 1:N_TRIALS
]


all_specs = [
    control_specs,
    roulette_specs,
    cfs_std_specs,
    cfs_adv_specs,
    doc_std_specs,
    doc_adv_specs,
    p_phc_specs,
    p_phc_p_frs_specs,
    p_phc_p_uhs_specs,
    cfs_qmeu_slow_specs,
    cfs_qmeu_fast_specs,
    doc_qmeu_slow_specs,
    doc_qmeu_fast_specs
]

#runners = [run_ng_easy_trial, run_ng_hard_trial, run_dct_trial, run_fsm_trial]
runners = [run_ng_easy_trial, run_ng_hard_trial, run_fsm_trial]
#runners = [run_ng_easy_trial,]
    
for runner in runners
    for specs in all_specs
        pmap(runner, specs)
    end
end


# Running the trials in parallel
#pmap(run_trial, 1:N_TRIALS)
