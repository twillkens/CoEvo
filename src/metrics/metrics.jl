module Metrics

export Common, Aggregators, Evaluations, Genotypes, Species

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("common/common.jl")
using .Common: Common

include("aggregators/aggregators.jl")
using .Aggregators: Aggregators

include("evaluations/evaluations.jl")
using .Evaluations: Evaluations

include("genotypes/genotypes.jl")
using .Genotypes: Genotypes

include("species/species.jl")
using .Species: Species

end