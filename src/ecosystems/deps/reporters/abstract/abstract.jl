module Abstract

export Report, Reporter, EcosystemReport, EcosystemReporter

abstract type Report end

abstract type Reporter end

abstract type EcosystemReport <: Report end

abstract type EcosystemReporter <: Reporter end

end