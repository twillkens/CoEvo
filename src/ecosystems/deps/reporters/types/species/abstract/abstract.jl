module Abstract

export SpeciesReport, SpeciesReporter

using ..Abstract: Metric, Reporter, Report

abstract type SpeciesReport{M <: Metric} <: Report end

abstract type SpeciesReporter{M <: Metric} <: Reporter end

end