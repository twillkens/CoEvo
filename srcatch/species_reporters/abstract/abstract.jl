module Abstract

export SpeciesReport, SpeciesReporter

using .....Ecosystems.Measures.Abstract: MeasureSet
using .....Ecosystems.Metrics.Species.Abstract: SpeciesMetric
using ...Reporters.Abstract: Reporter, Report

abstract type SpeciesReport{MET <: SpeciesMetric, MEA <: MeasureSet} <: Report end

abstract type SpeciesReporter{M <: SpeciesMetric} <: Reporter end


end