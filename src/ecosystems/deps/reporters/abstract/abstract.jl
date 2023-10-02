module Abstract

export Report, Reporter

using ....Ecosystems.Metrics.Abstract: Metric
using ....Ecosystems.Measurements.Abstract: Measurement

abstract type Report{MET <: Metric, MEA <: Measurement} end

abstract type Reporter{M <: Metric} end

end