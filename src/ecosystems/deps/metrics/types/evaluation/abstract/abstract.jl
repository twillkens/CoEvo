module Abstract

export EvaluationMetric

using ..Abstract: Metric

abstract type EvaluationMetric <: Metric end

end