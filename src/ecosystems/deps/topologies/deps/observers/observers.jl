"""
    Observations

The `Observations` module provides utilities to observe, track, and store outcomes resulting 
from interactions or evaluations in a coevolutionary process. It defines specific observation 
types, such as [`OutcomeObservation`](@ref), and corresponding configurations, 
like [`ScalarOutcomeObserver`](@ref).

# Key Types
- [`OutcomeObservation`](@ref): A structured type that captures the observed outcomes from interactions.
- [`ScalarOutcomeObserver`](@ref): A configuration type that specifies how outcomes should be observed and tracked.

# Dependencies
This module includes and depends on the `types/outcome.jl` file, which contains 
definitions related to outcomes, and the `methods/methods.jl` file that includes utility methods
for handling observations.

# Usage
Use this module when you want to define how outcomes are observed, tracked, and stored in your 
coevolutionary framework.

# Exports
The module exports: `OutcomeObservation`, `ScalarOutcomeObserver`, and `get_outcomes`.

# Files
- `types/outcome.jl`: Contains type definitions related to outcomes.
- `methods/methods.jl`: Contains utility methods for handling and processing observations.
"""
module Observers

export Abstract, Metrics, Basic

include("abstract/abstract.jl")
using .Abstract: Abstract

include("deps/metrics.jl")
using .Metrics: Metrics

include("types/basic.jl")
using .Basic: Basic

include("methods/methods.jl")


end