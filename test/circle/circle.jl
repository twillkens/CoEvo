using CoEvo.Concrete.Configurations.CircleExperiment
using CoEvo.Concrete.States.Basic

configuration = CircleExperimentConfiguration()

state = BasicEvolutionaryState(configuration, 1, configuration.seed)