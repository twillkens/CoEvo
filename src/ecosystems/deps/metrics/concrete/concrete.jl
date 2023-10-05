module Concrete

include("common/common.jl")
using .Common: Common

include("evaluations/evaluations.jl")
using .Evaluations: Evaluations

include("genotypes/genotypes.jl")
using .Genotypes: Genotypes

include("observations/observations.jl")
using .Observations: Observations

include("outcomes/outcomes.jl")
using .Outcomes: Outcomes

end