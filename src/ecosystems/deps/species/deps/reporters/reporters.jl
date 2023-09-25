module Reporters

export CohortMetricReporter

include("deps/reports.jl")

include("types/cohort_metric.jl")

include("methods/fitness.jl")
include("methods/size.jl")
include("methods/sum.jl")

end