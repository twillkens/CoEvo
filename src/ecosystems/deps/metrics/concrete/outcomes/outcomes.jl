module Outcomes

export NumbersGameOutcomeMetrics, PredictionGameOutcomeMetrics

include("numbers_games/numbers_games.jl")
using .NumbersGameOutcomeMetrics: NumbersGameOutcomeMetrics

include("prediction_games/prediction_games.jl")
using .PredictionGameOutcomeMetrics: PredictionGameOutcomeMetrics

end