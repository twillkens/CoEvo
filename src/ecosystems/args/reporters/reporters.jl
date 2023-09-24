module Reporters

export SpeciesStatisticalFeatureSetReport, RuntimeReport
export RuntimeReporter, FitnessReporter

include("args/reports/reports.jl")

include("types/runtime.jl")
include("types/fitness.jl")

using .Reports: RuntimeReport
using .Reports: SpeciesStatisticalFeatureSetReport, IndividualStatisticalFeatureSetReport 
using .Reports: extract_stat_features
# include("types/genotype.jl")

end