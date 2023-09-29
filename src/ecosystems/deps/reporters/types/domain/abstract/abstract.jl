
module Abstract

export DomainReport, DomainReporter, DomainMetric, Report, Reporter, Metric
export create_report

using .....Ecosystems.Abstract: Report, Reporter, Metric
using ...Observers.Abstract: Observation

abstract type DomianMetric <: Metric end

abstract type DomainReport{M <: DomainMetric} <: Report end

abstract type DomainReporter{M <: DomainMetric} <: Reporter end


end