module Concrete

export NumbersGameDomain, SymbolicRegressionDomain, ContinuousPredictionGameDomain
export LinguisticPredictionGameDomain, CollisionGameDomain

include("numbers_game/numbers_game.jl")
using .NumbersGame: NumbersGameDomain

include("sym_regress/sym_regress.jl")
using .SymbolicRegression: SymbolicRegressionDomain

include("cont_pred/cont_pred.jl")
using .ContinuousPredictionGame: ContinuousPredictionGameDomain

include("ling_pred/ling_pred.jl")
using .LinguisticPredictionGame: LinguisticPredictionGameDomain

include("collision_game/collision_game.jl")
using .CollisionGame: CollisionGameDomain

end