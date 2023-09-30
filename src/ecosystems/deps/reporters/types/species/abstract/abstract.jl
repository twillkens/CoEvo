module Abstract

export SpeciesReport, SpeciesReporter, Individual, SpeciesMetric, Evaluation, MeasureSet
export Genotype, Evaluation

using ...Abstract: Reporter, Report

using .....Ecosystems.Measures.Abstract: MeasureSet
using .....Ecosystems.Species.Individuals.Abstract: Individual
using .....Ecosystems.Metrics.Species.Abstract: SpeciesMetric
using .....Ecosystems.Species.Evaluators.Abstract: Evaluation
using .....Ecosystems.Domains.Observers.Abstract: Observation
using .....Ecosystems.Species.Individuals.Genotypes.Abstract: Genotype
using .....Ecosystems.Species.Evaluators.Abstract: Evaluation

abstract type SpeciesReport{MET <: SpeciesMetric, MEA <: MeasureSet} <: Report end

abstract type SpeciesReporter{M <: SpeciesMetric} <: Reporter end


end