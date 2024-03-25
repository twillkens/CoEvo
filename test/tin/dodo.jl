using CoEvo.Concrete.Configurations.MaxSolve
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces
using Distributed



config = MaxSolveConfiguration(
    seed = abs(rand(Int)),
    n_learner_population = 30, 
    n_learner_children = 30, 
    n_test_population = 30, 
    n_test_children = 30,
    max_learner_archive_size = 25,
    n_generations = 500,
    n_dimensions = 3,
    min_mutation = -0.06,
    max_mutation = 0.04,
    domain = "CompareOnOne",
    n_workers = nworkers(),
    task = "dct"
)

state = BasicEvolutionaryState(config)
evolve!(state)
println("done")

#rule =[1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0]
