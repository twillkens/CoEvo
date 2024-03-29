using CoEvo.Concrete.Configurations.MaxSolve
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces
using Distributed



config = MaxSolveConfiguration(
    seed = abs(rand(Int)),
    n_learner_population = 20, 
    n_learner_children = 20, 
    n_test_population = 20, 
    n_test_children = 20,
    max_learner_archive_size = 20,
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
