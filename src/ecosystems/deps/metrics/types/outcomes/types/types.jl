module Types

export NumbersGame, Generic, ContinuousPredictionGame

include("numbers_game/numbers_game.jl")
using .NumbersGame: NumbersGame

include("generic/generic.jl")
using .Generic: Generic

include("cont_pred/cont_pred.jl")
using .ContinuousPredictionGame: ContinuousPredictionGame

end