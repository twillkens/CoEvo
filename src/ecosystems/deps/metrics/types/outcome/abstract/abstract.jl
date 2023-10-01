module Abstract

export OutcomeMetric

using ...Metrics.Abstract: Metric

abstract type OutcomeMetric <: Metric end

end