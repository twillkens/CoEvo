module Abstract

export Observation, Observer, ObservationMetric

using ....Ecosystems.Metrics.Observation.Abstract: ObservationMetric

using ...Domains.Abstract: Domain

abstract type Observation end

abstract type Observer end

end