module Methods

export Interact, NumbersGame

include("interact.jl")
using .Interact: Interact

include("numbers_game.jl")
using .NumbersGame: NumbersGame


end