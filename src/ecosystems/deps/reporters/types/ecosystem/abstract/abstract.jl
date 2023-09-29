module Abstract

export EcosystemReport, EcosystemReporter

abstract type EcosystemReport{M <: EcosystemMetric} <: Report end

abstract type EcosystemReporter{M <: EcosystemMetric} <: Reporter end

end