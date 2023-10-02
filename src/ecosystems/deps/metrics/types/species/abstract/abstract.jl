module Abstract

export SpeciesMetric

using ....Metrics.Abstract: Metric

abstract type SpeciesMetric <: Metric end

end