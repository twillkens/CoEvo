"""
    Reporters

This module provides utilities for reporting and analyzing the performance and metrics of 
evolutionary algorithms. The currently implemented reporter is `CohortMetricReporter`, which 
captures and reports metrics for cohorts of individuals.

# Modules and Includes
The module makes use of external dependencies and includes files for:
- Dependencies related to reporting (`deps/reports.jl`).
- The main type definition for `CohortMetricReporter` (`types/cohort_metric.jl`).
- Associated methods for the types (`methods/methods.jl`).
"""
module Reporters

export CohortMetricReporter

include("deps/reports.jl")
include("types/cohort_metric.jl")
include("methods/methods.jl")

end

module Reporters

export CohortMetricReporter

include("deps/reports.jl")

include("types/cohort_metric.jl")

include("methods/methods.jl")

end