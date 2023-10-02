module Abstract

export InteractionMetric

using ....Metrics.Abstract: Metric

abstract type InteractionMetric <: Metric end

end