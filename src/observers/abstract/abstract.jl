export Observation, Observer

using ..Metrics: Metric

abstract type Observation{M <: Metric, D <: Any} end

abstract type Observer{M <: Metric} end
