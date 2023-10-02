module Abstract

export ObservationMetric

using ....Metrics.Abstract: Metric

abstract type ObservationMetric <: Metric end

end