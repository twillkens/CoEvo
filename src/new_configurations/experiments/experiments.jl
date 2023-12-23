module ExperimentConfigurations

export PredictionGame

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("prediction_game/prediction_game.jl")
using .PredictionGame: PredictionGame

end