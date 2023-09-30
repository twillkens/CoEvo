module Abstract

export EcosystemReport, EcosystemReporter

using .....Ecosystems.Metrics.Ecosystem.Abstract: EcosystemMetric
using ...Abstract: Report, Reporter

abstract type EcosystemReport{M <: EcosystemMetric} <: Report end

abstract type EcosystemReporter{M <: EcosystemMetric} <: Reporter end

end