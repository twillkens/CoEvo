using Distributed
using CoEvo.Concrete.Configurations.MaxSolve
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces

# Experiment parameters
N_TRIALS = 5
N_WORKERS = nworkers()

for trial in 1:N_TRIALS
    seed = abs(rand(Int))
    println("Trial: ", trial, " Seed: ", seed)

    config = DensityClassificationTaskConfiguration(
        id = trial,
        seed = seed,
        n_workers = N_WORKERS,
        n_generations = 200,
        n_timesteps = 320,
        n_validation_initial_conditions = 10_000,

        # Learner population parameters
        n_learner_population = 100, 
        n_learner_parents = 100,
        n_learner_children = 100, 

        max_learner_archive_size = 0,
        max_active_learner_archive = 0,

        max_learner_retiree_size = 0,
        max_active_learner_retirees = 0,

        learner_recombiner = "clone",
        rule_length = 128,
        learner_flip_chance = 0.2,

        # Test population parameters
        n_test_population = 100, 
        n_test_parents = 100,
        n_test_children = 100,

        max_test_archive_size = 0,
        max_active_test_archive = 0,

        max_test_retiree_size = 200,
        max_active_test_retirees = 10,

        test_recombiner = "clone",
        initial_condition_length = 149,
        test_flip_chance = 0.05,

        # MaxSolve parameters
        algorithm = "dodo",

    )

    state = BasicEvolutionaryState(config)
    evolve!(state)
    println("done")
end
