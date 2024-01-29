using CoEvo.Concrete.Configurations.NumbersGame
using CoEvo.Concrete.States.Basic
using CoEvo.Interfaces

config = NumbersGameExperimentConfiguration(
    domain = "CompareOnOne", 
    evaluator_type = "distinction", 
    clusterer_type = "global_kmeans", 
    distance_method = "euclidean", 
    seed = abs(rand(Int)),
    archive_type = "basic",
    n_workers = 1,
    n_generations = 1_000
)
state = BasicEvolutionaryState(config)
#println(state)
state = evolve!(state)
println("done")