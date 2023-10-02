module Abstract

export Domain

using ....Ecosystems.Metrics.Outcomes.Abstract: OutcomeMetric

abstract type Domain{O <: OutcomeMetric} end

end