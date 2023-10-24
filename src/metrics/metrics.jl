module Metrics

export Common, Evaluations, Genotypes, Observations

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("common/common.jl")
using .Common: Common

include("evaluations/evaluations.jl")
using .Evaluations: Evaluations

include("genotypes/genotypes.jl")
using .Genotypes: Genotypes

include("observations/observations.jl")
using .Observations: Observations

end