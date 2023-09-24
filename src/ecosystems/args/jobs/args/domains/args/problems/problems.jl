
module Problems

export NumbersGameProblem, interact

include("types/numbers_game/numbers_game.jl")

using .NumbersGame: NumbersGameProblem, interact

end


#include("lingpred/lingpred.jl")
# include("delphi/delphi.jl")
#include("sym_regression/sym_regression.jl")
#include("prediction/prediction.jl")