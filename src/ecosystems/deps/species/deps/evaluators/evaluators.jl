"""
    Evaluations

This module provides tools and configurations for evaluating individuals in a coevolutionary ecosystem.
It supports various evaluation types, with the included type being `ScalarFitnessEvaluation`.
"""
module Evaluators

export Abstract, Interfaces, Criteria, Types

# Include abstract definitions and interfaces relevant to evaluations.
include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("deps/criteria/criteria.jl")
using .Criteria: Criteria

# Include specific evaluation types.
include("types/types.jl")
using .Types: Types

end
