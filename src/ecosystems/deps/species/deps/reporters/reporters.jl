"""
    Reporters

This module provides utilities for reporting and analyzing the performance and metrics of 
evolutionary algorithms. The currently implemented reporter is `BasicSpeciesReporter`, which 
captures and reports metrics for cohorts of individuals.

# Modules and Includes
The module makes use of external dependencies and includes files for:
- Dependencies related to reporting (`deps/reports.jl`).
- The main type definition for `BasicSpeciesReporter` (`types/cohort_metric.jl`).
- Associated methods for the types (`methods/methods.jl`).
"""
module Reporters

export BasicSpeciesReporter, Abstract, Metrics

include("deps/metrics.jl")
using .Metrics

include("abstract/abstract.jl")
using .Abstract

include("types/basic.jl")

include("methods/methods.jl")

end