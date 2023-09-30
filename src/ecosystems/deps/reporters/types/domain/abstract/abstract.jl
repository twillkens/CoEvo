module Abstract

export DomainReport, DomainReporter, DomainMetric, Observation, MeasureSet

using ....Ecosystems.Abstract: Metric
using ...Abstract: Report, Reporter
using ....Ecosystems.Domains.Observers.Abstract: Observation
using ....Ecosystems.Metrics.Observation.Abstract: ObservationMetric
using ....Ecosystems.Measures.Abstract: MeasureSet

abstract type DomainMetric <: Metric end

abstract type DomainReport{
    O <: ObservationMetric, 
    D <: DomainMetric,
    M <: MeasureSet
} <: Report end

abstract type DomainReporter{D <: DomainMetric} <: Reporter end


end