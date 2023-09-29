module Abstract

export DomainReport, DomainReporter, DomainMetric

using ....Ecosystems.Abstract: Metric
using ...Abstract: Report, Reporter

abstract type DomainMetric <: Metric end

abstract type DomainReport{D <: DomainMetric} <: Report end

abstract type DomainReporter{D <: DomainMetric} <: Reporter end


end