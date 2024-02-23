module Configurations

export NumbersGame, DensityClassification #, CircleExperiment

include("numbers_game/numbers_game.jl")
using .NumbersGame: NumbersGame

include("density_classification/density_classification.jl")
using .DensityClassification: DensityClassification

#include("circle_experiment/circle_experiment.jl")
#using .CircleExperiment: CircleExperiment

end