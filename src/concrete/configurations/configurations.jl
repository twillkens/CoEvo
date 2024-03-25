module Configurations

export NumbersGame, DensityClassification, MaxSolve #, CircleExperiment

include("numbers_game/numbers_game.jl")
using .NumbersGame: NumbersGame

include("density_classification/density_classification.jl")
using .DensityClassification: DensityClassification

include("maxsolve/maxsolve.jl")
using .MaxSolve: MaxSolve

#include("circle_experiment/circle_experiment.jl")
#using .CircleExperiment: CircleExperiment

end