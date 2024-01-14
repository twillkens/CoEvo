module Domains

export NumbersGame, SymbolicRegression, PredictionGame

include("numbers_game/numbers_game.jl")
using .NumbersGame: NumbersGame

include("symbolic_regression/symbolic_regression.jl")
using .SymbolicRegression: SymbolicRegression

include("prediction_game/prediction_game.jl")
using .PredictionGame: PredictionGame

end