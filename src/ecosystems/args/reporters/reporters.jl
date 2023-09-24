module Reporters

export SpeciesStatisticalFeatureReport, RuntimeReport
export FitnessReporter

include("args/reports/reports.jl")

include("types/fitness.jl")
# include("types/genotype.jl")

end