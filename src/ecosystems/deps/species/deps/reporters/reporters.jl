module Reporters

export FitnessEvaluationReporter, SizeGenotypeReporter

include("deps/reports.jl")

include("abstract/abstract.jl")

include("types/evaluation.jl")
include("types/genotype.jl")


end