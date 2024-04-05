using CoEvo.Concrete.Configurations.MaxSolve
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces
using Distributed


N_POP = 20
N_CHILDREN = 40
N_ARCHIVE = 10

config = MaxSolveConfiguration(
    seed = abs(rand(Int)),
    n_learner_population = N_POP, 
    n_learner_children = N_CHILDREN, 
    n_test_population = N_POP, 
    n_test_children = N_CHILDREN,
    max_learner_archive_size = N_ARCHIVE,
    n_generations = 2000,
    n_dimensions = 3,
    min_mutation = -0.06,
    max_mutation = 0.04,
    domain = "CompareOnOne",
    n_workers = nworkers(),
    task = "dct",
    learner_flip_chance = 0.01,
    test_flip_chance = 0.01
)

state = BasicEvolutionaryState(config)
evolve!(state)
println("done")

#rule =[1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0]
