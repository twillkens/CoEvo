module Abstract

export EcosystemReport, EcosystemReporter

using ...Ecosystems.Abstract: Reporter

abstract type EcosystemReport <: Report end

abstract type EcosystemReporter <: Reporter end

end