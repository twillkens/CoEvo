"""
    Evaluations

This module provides tools and configurations for evaluating individuals in a coevolutionary ecosystem.
It supports various evaluation types, with the included type being `ScalarFitnessEvaluation`.
"""
module Evaluators

export ScalarFitnessEvaluation, ScalarFitnessEvaluator

# Include abstract definitions and interfaces relevant to evaluations.
include("abstract/abstract.jl")
using .Abstract

include("utilities/utilities.jl")
using .Utilities

# Include specific evaluation types.
include("types/scalar_fitness.jl")
using .ScalarFitness: ScalarFitnessEvaluation, ScalarFitnessEvaluator


end
