using Distributed
using CoEvo.Concrete.Configurations.MaxSolve
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces

# Experiment parameters
N_TRIALS = 5
N_WORKERS = nworkers()
N_GENERATIONS = 20
N_TIMESTEPS = 320
N_VALIDATION_INITIAL_CONDITIONS = 10_000

# Learner population parameters
N_LEARNER_POP = 20
N_LEARNER_CHILDREN = 20
LEARNER_RECOMBINER = "clone"
RULE_LENGTH = 128
LEARNER_FLIP_CHANCE = 0.02

# Test population parameters
N_TEST_POP = 20
N_TEST_CHILDREN = 20
TEST_RECOMBINER = "clone"
INITIAL_CONDITION_LENGTH = 149
TEST_FLIP_CHANCE = 0.05

# MaxSolve parameters
ALGORITHM = "standard"
N_MAXSOLVE_ARCHIVE = 0

for trial in 1:N_TRIALS
    seed = abs(rand(Int))
    println("Trial: ", trial, " Seed: ", seed)

    config = DensityClassificationTaskConfiguration(
        id = trial,
        seed = seed,
        n_workers = N_WORKERS,
        n_generations = N_GENERATIONS,
        n_timesteps = N_TIMESTEPS,
        n_validation_initial_conditions = N_VALIDATION_INITIAL_CONDITIONS,

        # Learner population parameters
        n_learner_population = N_LEARNER_POP, 
        n_learner_children = N_LEARNER_CHILDREN, 
        learner_recombiner = LEARNER_RECOMBINER,
        rule_length = RULE_LENGTH,
        learner_flip_chance = LEARNER_FLIP_CHANCE,

        # Test population parameters
        n_test_population = N_TEST_POP, 
        n_test_children = N_TEST_CHILDREN,
        test_recombiner = TEST_RECOMBINER,
        initial_condition_length = INITIAL_CONDITION_LENGTH,
        test_flip_chance = TEST_FLIP_CHANCE,

        # MaxSolve parameters
        algorithm = ALGORITHM,
        max_learner_archive_size = N_MAXSOLVE_ARCHIVE,
    )

    state = BasicEvolutionaryState(config)
    evolve!(state)
    println("done")
end

#rule =[1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0]
