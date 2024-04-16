module Domains

export NumbersGame, DensityClassification

include("numbers_game/numbers_game.jl")
using .NumbersGame: NumbersGame

include("density_classification/density_classification.jl")
using .DensityClassification: DensityClassification

end