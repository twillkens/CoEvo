module Abstract

export Observation, Observer, ObservationMetric, Environment

using ....Ecosystems.Metrics.Observation.Abstract: ObservationMetric

using ...Environments.Abstract: Environment

abstract type Observation end

abstract type Observer end

end