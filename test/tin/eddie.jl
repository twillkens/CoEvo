using CoEvo.Concrete.Configurations.MaxSolve
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces
using Distributed


N_TRIALS = 20
N_LEARNER_POP = 100
N_LEARNER_CHILDREN = 100
N_TEST_POP = 100
N_TEST_CHILDREN = 100
N_ARCHIVE = 0
N_GENERATIONS = 200

for trial in 1:N_TRIALS
    config = MaxSolveConfiguration(
        id = trial,
        seed = abs(rand(Int)),
        n_learner_population = N_LEARNER_POP, 
        n_learner_children = N_LEARNER_CHILDREN, 
        n_test_population = N_TEST_POP, 
        n_test_children = N_TEST_CHILDREN,
        max_learner_archive_size = N_ARCHIVE,
        n_generations = N_GENERATIONS,
        n_dimensions = 3,
        min_mutation = -0.06,
        max_mutation = 0.04,
        domain = "CompareOnOne",
        #n_workers = nworkers(),
        n_workers = 1,
        task = "dct",
        learner_flip_chance = 0.02,
        test_flip_chance = 0.05
    )

    state = BasicEvolutionaryState(config)
    evolve!(state)
    println("done")
end
