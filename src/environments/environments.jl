module Environments

export Stateless, LinguisticPredictionGame, CollisionGame
export ContinuousPredictionGame

import ..Observers: observe!

using ..Phenotypes: Phenotype
using ..Domains: Domain
using ..Observers: Observer

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("stateless/stateless.jl")
using .Stateless: Stateless

include("linguistic_prediction_game/linguistic_prediction_game.jl")
using .LinguisticPredictionGame: LinguisticPredictionGame

include("collision_game/collision_game.jl")
using .CollisionGame: CollisionGame

include("continuous_prediction_game/continuous_prediction_game.jl")
using  .ContinuousPredictionGame: ContinuousPredictionGame

end
