module Abstract

export Observation, Observer, ObserverCreator

using ....Metrics.Observation.Abstract: ObservationMetric

abstract type Observation{O <: ObservationMetric, D <: Any} end

abstract type Observer{O <: ObservationMetric} end

abstract type ObserverCreator{O <: ObservationMetric} end

end