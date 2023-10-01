module Abstract

export OutcomeMetric

using ...Abstract: Metric

abstract type OutcomeMetric <: Metric end

end