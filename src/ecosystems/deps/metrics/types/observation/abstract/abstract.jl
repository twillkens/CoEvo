module Abstract

export ObservationMetric

using ...Abstract: Metric

abstract type ObservationMetric <: Metric end

end