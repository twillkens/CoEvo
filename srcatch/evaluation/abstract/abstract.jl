module Abstract

export EvaluationMetric

using ..Species.Abstract: SpeciesMetric

abstract type EvaluationMetric <: SpeciesMetric end

end