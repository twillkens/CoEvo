using CoEvo.NewConfigurations.ExperimentConfigurations.NumbersGame: NumbersGameExperimentConfiguration
using CoEvo.States.Evolutionary: EvolutionaryState, evolve!

config = NumbersGameExperimentConfiguration(
    game = "Relativism", 
    evaluation = "disco", 
    clusterer = "xmeans", 
    distance_method = "euclidean", 
    seed=abs(rand(Int))
)
state = EvolutionaryState(config)
println(state)
state = evolve!(state)
println("done")