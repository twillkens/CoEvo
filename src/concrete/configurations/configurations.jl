module Configurations

export NumbersGame, CircleExperiment

include("numbers_game/numbers_game.jl")
using .NumbersGame: NumbersGame

include("circle_experiment/circle_experiment.jl")
using .CircleExperiment: CircleExperiment

end