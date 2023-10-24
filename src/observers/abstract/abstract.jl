module Abstract

export Observation, Observer

using ...Metrics.Abstract: Metric

abstract type Observation{M <: Metric, D <: Any} end

abstract type Observer{M <: Metric} end

end