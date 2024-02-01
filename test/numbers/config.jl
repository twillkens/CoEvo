using CoEvo.Concrete.Configurations.NumbersGame
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces

config = NumbersGameExperimentConfiguration(
    id = 1,
    domain = "CompareOnOne", 
    evaluator_type = "distinction", 
    clusterer_type = "global_kmeans", 
    distance_method = "euclidean", 
    seed = abs(rand(Int)),
    archive_type = "none",
    n_workers = 1,
    n_generations = 10_000,
    mode = "archive_discrete"
)
state = BasicEvolutionaryState(config)
#println(state)
evolve!(state)
println("done")