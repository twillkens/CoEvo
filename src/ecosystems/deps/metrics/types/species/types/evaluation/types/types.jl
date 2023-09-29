module Types

export GenotypeSum, GenotypeSize

using ...Abstract: EvaluationMetric

Base.@kwdef struct EvaluationFitnessMetric <: GenotypeMetric
    name::String = "GenotypeSum"
end


end
