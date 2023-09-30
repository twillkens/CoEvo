module Abstract

export Observation, Observer, ObservationMetric, Environment

using ...Environments.Abstract: Environment
using .....Ecosystems.Metrics.Observation.Abstract: ObservationMetric

abstract type Observation end

abstract type Observer end

end