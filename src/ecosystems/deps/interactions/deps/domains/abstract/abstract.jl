module Abstract

export Domain

using ....Ecosystems.Metrics.Abstract: Metric

abstract type Domain{O <: Metric} end

end