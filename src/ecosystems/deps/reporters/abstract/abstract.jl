module Abstract

export Report, Reporter

using ....Ecosystems.Metrics.Abstract: Metric
using ....Ecosystems.Measures.Abstract: MeasureSet

abstract type Report{MET <: Metric, MEA <: MeasureSet} end

abstract type Reporter{M <: Metric} end

end