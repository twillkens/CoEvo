module Environments

export Stateless, LinguisticPredictionGame, CollisionGame, ContinuousPredictionGame
export ElementaryCellularAutomata

include("stateless/stateless.jl")
using .Stateless: Stateless

include("linguistic_prediction_game/linguistic_prediction_game.jl")
using .LinguisticPredictionGame: LinguisticPredictionGame

include("collision_game/collision_game.jl")
using .CollisionGame: CollisionGame

include("continuous_prediction_game/continuous_prediction_game.jl")
using  .ContinuousPredictionGame: ContinuousPredictionGame

include("elementary_cellular_automata/elementary_cellular_automata.jl")
using .ElementaryCellularAutomata: ElementaryCellularAutomata

end
