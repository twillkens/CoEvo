module Abstract

export OutcomeMetric, Domain

using ...Metrics.Abstract: Metric

abstract type OutcomeMetric <: Metric end

abstract type Domain{O <: OutcomeMetric} end

end