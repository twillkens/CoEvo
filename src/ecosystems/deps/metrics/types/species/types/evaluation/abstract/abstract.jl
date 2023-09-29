module Abstract

export EvaluationMetric

using ...Abstract: SpeciesMetric

abstract type EvaluationMetric <: SpeciesMetric end

end