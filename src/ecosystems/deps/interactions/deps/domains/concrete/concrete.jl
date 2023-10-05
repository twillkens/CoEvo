module Concrete

export NumbersGameDomain, SymbolicRegressionDomain, ContinuousPredictionGameDomain
export LinguisticPredictionGameDomain

include("numbers_game.jl")
using .NumbersGame: NumbersGameDomain

include("sym_regress.jl")
using .SymbolicRegression: SymbolicRegressionDomain

include("cont_pred.jl")
using .ContinuousPredictionGame: ContinuousPredictionGameDomain

include("ling_pred.jl")
using .LinguisticPredictionGame: LinguisticPredictionGameDomain

end