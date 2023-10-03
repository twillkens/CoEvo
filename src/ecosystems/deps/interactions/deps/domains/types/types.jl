module Types

export NumbersGame, SymbolicRegression, ContinuousPredictionGame

include("numbers_game.jl")
using .NumbersGame: NumbersGame

include("sym_regress.jl")
using .SymbolicRegression: SymbolicRegression

include("cont_pred.jl")
using .ContinuousPredictionGame: ContinuousPredictionGame

end