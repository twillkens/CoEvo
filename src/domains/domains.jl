module Domains

export Abstract, Interfaces, NumbersGame, SymbolicRegression, PredictionGame

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("numbers_game/numbers_game.jl")
using .NumbersGame: NumbersGame

include("symbolic_regression/symbolic_regression.jl")
using .SymbolicRegression: SymbolicRegression

include("prediction_game/prediction_game.jl")
using .PredictionGame: PredictionGame

end