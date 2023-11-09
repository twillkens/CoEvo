module Metrics

export Common, Aggregators, Evaluations, Species, Individuals, Genotypes

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("common/common.jl")
using .Common: Common

include("aggregators/aggregators.jl")
using .Aggregators: Aggregators

include("evaluations/evaluations.jl")
using .Evaluations: Evaluations

include("species/species.jl")
using .Species: Species

include("individuals/individuals.jl")
using .Individuals: Individuals

include("genotypes/genotypes.jl")
using .Genotypes: Genotypes

end