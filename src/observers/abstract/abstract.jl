export Observation, Observer, PhenotypeObserver

using ..Metrics: Metric

abstract type Observation end

abstract type Observer end

abstract type PhenotypeObserver <: Observer end
