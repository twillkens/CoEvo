"""
    Evaluations

This module provides tools and configurations for evaluating individuals in a coevolutionary ecosystem.
It supports various evaluation types, with the included type being `ScalarFitnessEvaluation`.
"""
module Evaluations

export ScalarFitnessEvaluation, ScalarFitnessEvaluationConfiguration, sort_indiv_evals

# Include abstract definitions and interfaces relevant to evaluations.
include("abstract/abstract.jl")

using .Abstract: sort_indiv_evals

# Include specific evaluation types.
include("types/scalar_fitness.jl")

using .Abstract: sort_indiv_evals
using .ScalarFitness: ScalarFitnessEvaluation, ScalarFitnessEvaluationConfiguration, sort_indiv_evals

end
