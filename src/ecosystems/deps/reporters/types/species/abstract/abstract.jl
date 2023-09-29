module Abstract

export SpeciesReport, SpeciesReporter

using ...Abstract: Metric, Reporter, Report

abstract type SpeciesReport{M <: SpeciesMetric} <: Report end

abstract type SpeciesReporter{M <: SpeciesMetric} <: Reporter end

end