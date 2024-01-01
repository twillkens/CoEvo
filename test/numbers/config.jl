using CoEvo.NewConfigurations.ExperimentConfigurations.NumbersGame: NumbersGameExperimentConfiguration
using CoEvo.States.Evolutionary: EvolutionaryState, evolve!

config = NumbersGameExperimentConfiguration(game = "COA", evaluation = "disco", seed=666)
state = EvolutionaryState(config)
println(state)
evolve!(state)