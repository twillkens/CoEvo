"""
    Evaluations

This module provides tools and configurations for evaluating individuals in a coevolutionary ecosystem.
It supports various evaluation types, with the included type being `ScalarFitnessEvaluation`.
"""
module Evaluators

export Abstract, Interfaces, Null, ScalarFitness, NSGAII

# Include abstract definitions and interfaces relevant to evaluations.
include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("null/null.jl")
using .Null: Null

include("scalar_fitness/scalar_fitness.jl")
using .ScalarFitness: ScalarFitness

include("nsga-ii/nsga-ii.jl")
using .NSGAII: NSGAII

end
