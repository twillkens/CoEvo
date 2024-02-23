module Domains

export NumbersGame, SymbolicRegression, PredictionGame, DensityClassification

include("numbers_game/numbers_game.jl")
using .NumbersGame: NumbersGame

include("symbolic_regression/symbolic_regression.jl")
using .SymbolicRegression: SymbolicRegression

include("prediction_game/prediction_game.jl")
using .PredictionGame: PredictionGame

include("density_classification/density_classification.jl")
using .DensityClassification: DensityClassification

end