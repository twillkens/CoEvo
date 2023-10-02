module Abstract

export EvaluationMetric

using ....Metrics.Abstract: Metric

abstract type EvaluationMetric <: Metric end

end