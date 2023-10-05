module Concrete

export Default, Stateless, Tape, LinguisticPredictionGame

include("default/default.jl")
using .Default: Default

include("stateless/stateless.jl")
using .Stateless: Stateless

include("tape/tape.jl")
using .Tape: Tape

include("ling_pred/ling_pred.jl")
using .LinguisticPredictionGame: LinguisticPredictionGame

end