using CoEvo.Concrete.Configurations.MaxSolve
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces
using Distributed
using Random


N_LEARNER_POP = 100
N_LEARNER_CHILDREN = 100
N_TEST_POP = 100
N_TEST_CHILDREN = 100
N_ARCHIVE = 0
N_GENERATIONS = 500

for trial in 1:10
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
        n_dimensions = 5,
        min_mutation = -0.15,
        max_mutation = 0.1,
        use_delta = false,
        delta = 0.25,
        domain = "CompareOnOne",
        n_workers = nworkers(),
        task = "numbers_game", 
        #task = "dct",
        learner_flip_chance = 0.02,
        test_flip_chance = 0.05
    )

    state = BasicEvolutionaryState(config)
    evolve!(state)
    println("done")
end

#rule =[1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0]
