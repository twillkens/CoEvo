module Abstract

export Report, Reporter, EcosystemReport, EcosystemReporter, Observation, Individual

abstract type Report end

abstract type Reporter end

abstract type EcosystemReport <: Report end

abstract type EcosystemReporter <: Reporter end

using ....Ecosystems.Domains.Observers.Abstract: Observation
using ....Ecosystems.Species.Individuals.Abstract: Individual
using ....Ecosystems.Species.Evaluators.Abstract: Evaluation

end