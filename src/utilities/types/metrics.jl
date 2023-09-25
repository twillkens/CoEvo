module Metrics

export GenotypeSum, GenotypeSize, EvaluationFitness

using ...CoEvo.Abstract: GenotypeMetric, EvaluationMetric

Base.@kwdef struct GenotypeSum <: GenotypeMetric
    name::String = "GenotypeSum"
end

Base.@kwdef struct GenotypeSize <: GenotypeMetric
    name::String = "GenotypeSize"
end

Base.@kwdef struct EvaluationFitness <: EvaluationMetric
    name::String = "EvaluationFitness"
end

end