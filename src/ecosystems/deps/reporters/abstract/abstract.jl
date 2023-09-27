module Abstract

export EcosystemReport, EcosystemReporter, Archiver

using ...Ecosystems.Abstract: Report, Reporter, Archiver

abstract type EcosystemReport <: Report end

abstract type EcosystemReporter <: Reporter end

end