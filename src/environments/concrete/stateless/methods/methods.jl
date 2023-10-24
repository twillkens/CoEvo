module StatelessMethods

export NumbersGame, SymbolicRegression

include("numbers_game.jl")
using .NumbersGame: NumbersGame

include("sym_regress.jl")
using .SymbolicRegression: SymbolicRegression

end