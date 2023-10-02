module Abstract

export Domain

using ....Ecosystems.Metrics.Outcome.Abstract: OutcomeMetric

abstract type Domain{O <: OutcomeMetric} end

end