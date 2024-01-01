module ExperimentConfigurations

export PredictionGame, NumbersGame

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("prediction_game/prediction_game.jl")
using .PredictionGame: PredictionGame

include("numbers_game/numbers_game.jl")
using .NumbersGame: NumbersGame

end