module Methods

export Interact, NumbersGame, SymbolicRegression, ContinuousPredictionGame

include("interact.jl")
using .Interact: Interact

include("numbers_game.jl")
using .NumbersGame: NumbersGame

include("sym_regress.jl")
using .SymbolicRegression: SymbolicRegression

include("cont_pred.jl")
using .ContinuousPredictionGame: ContinuousPredictionGame


end