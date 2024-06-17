using CoEvo.Concrete.Configurations.MaxSolve
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces
using Distributed
using Random


N_LEARNER_POP = 100
N_LEARNER_CHILDREN = 100
N_TEST_POP = 100
N_TEST_CHILDREN = 100
N_ARCHIVE = 1000
N_GENERATIONS = 20000
N_TRIALS = 1

for trial in 1:N_TRIALS
    seed = abs(rand(Int))
    Random.seed!(seed)

    config = MaxSolveConfiguration(
        id = trial,
        tag = 2,
        seed = seed,
        learner_algorithm = "disco",
        test_algorithm = "qmeu",
        n_learner_population = N_LEARNER_POP, 
        n_learner_children = N_LEARNER_CHILDREN, 
        n_test_population = N_TEST_POP, 
        n_test_children = N_TEST_CHILDREN,
        max_learner_archive_size = N_ARCHIVE,
        n_generations = N_GENERATIONS,
        n_workers = nworkers(),
        task = "fsm", 
    )

    state = BasicEvolutionaryState(config)
    evolve!(state)
    println("done")
end
