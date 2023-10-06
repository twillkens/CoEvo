module Outcomes

export NumbersGameOutcomeMetrics, PredictionGameOutcomeMetrics, CollisionGameOutcomeMetrics

include("numbers_game/numbers_game.jl")
using .NumbersGameOutcomeMetrics: NumbersGameOutcomeMetrics

include("prediction_game/prediction_game.jl")
using .PredictionGameOutcomeMetrics: PredictionGameOutcomeMetrics

include("collision_game/collision_game.jl")
using .CollisionGameOutcomeMetrics: CollisionGameOutcomeMetrics

end