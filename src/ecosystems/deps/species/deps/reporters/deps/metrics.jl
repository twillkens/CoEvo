"""
    Metrics

The `Metrics` module provides predefined metrics related to genotypes and evaluations within a 
coevolutionary context. These metrics offer insights and measurements for different aspects of 
the entities in the coevolutionary system.

# Key Types
- [`GenotypeSum`](@ref): A metric representing the sum of a genotype's elements.
- [`GenotypeSize`](@ref): A metric indicating the size or length of a genotype.
- [`EvaluationFitness`](@ref): A metric for assessing the fitness value from an evaluation.

# Usage
These metrics can be utilized in various stages of the coevolutionary process, from evaluating 
the features of genotypes to analyzing the outcomes of evaluations.

# Exports
The module exports the following types: `GenotypeSum`, `GenotypeSize`, and `EvaluationFitness`.
"""

module Metrics

export GenotypeSum, GenotypeSize, EvaluationFitness

using ...CoEvo.Abstract: GenotypeMetric, EvaluationMetric

"""
    GenotypeSum

A metric that represents the sum of a genotype's elements.

# Fields
- `name::String`: Name of the metric, defaulting to "GenotypeSum".
"""
Base.@kwdef struct GenotypeSum <: GenotypeMetric
    name::String = "GenotypeSum"
end

"""
    GenotypeSize

A metric used to indicate the size or length of a genotype.

# Fields
- `name::String`: Name of the metric, defaulting to "GenotypeSize".
"""
Base.@kwdef struct GenotypeSize <: GenotypeMetric
    name::String = "GenotypeSize"
end

"""
    EvaluationFitness

A metric designed for assessing the fitness value from an evaluation.

# Fields
- `name::String`: Name of the metric, defaulting to "EvaluationFitness".
"""
Base.@kwdef struct EvaluationFitness <: EvaluationMetric
    name::String = "EvaluationFitness"
end

end
