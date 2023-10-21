module Concrete

export PredictionGames, PredictionGameTrialConfiguration

include("prediction_games/prediction_games.jl")
using .PredictionGames: PredictionGames, PredictionGameTrialConfiguration


end