module Configurations

export NumbersGame, PredictionGame

import ..Ecosystems: evolve!

using HDF5: File, Group, h5open
using StableRNGs: StableRNG
using ..Ecosystems: EcosystemCreator

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("helpers/helpers.jl")

include("numbers_game/numbers_game.jl")
using .NumbersGame: NumbersGame

include("prediction_game/prediction_game.jl")
using .PredictionGame: PredictionGame

include("load.jl")

end