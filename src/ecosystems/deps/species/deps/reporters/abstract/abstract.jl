module Abstract

export SpeciesReport, SpeciesReporter
export Report, Reporter, Metric
export Individual, Genotype, Evaluation

using ....Ecosystems.Abstract: Report, Reporter, Metric
using ...Individuals.Abstract: Individual
using ...Individuals.Genotypes.Abstract: Genotype
using ....Species.Evaluators.Abstract: Evaluation

abstract type SpeciesReporter{M <: Metric} <: Reporter end

abstract type SpeciesReport{M <: Metric} <: Report end


end