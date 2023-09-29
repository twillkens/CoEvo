module Abstract

export DomainMetric

using ...Abstract: Metric

abstract type DomainMetric <: Metric end

end