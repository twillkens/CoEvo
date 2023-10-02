module Abstract

export EcosystemMetric

using ....Metrics.Abstract: Metric

abstract type EcosystemMetric <: Metric end

end