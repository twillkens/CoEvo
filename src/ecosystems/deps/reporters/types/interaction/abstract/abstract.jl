module Abstract

export InteractionReport, InteractionReporter, OutcomeMetric, Observation, MeasureSet

using ....Ecosystems.Abstract: Metric
using ...Abstract: Report, Reporter
using ....Ecosystems.Interactions.Observers.Abstract: Observation
using ....Ecosystems.Metrics.Observation.Abstract: ObservationMetric
using ....Ecosystems.Measures.Abstract: MeasureSet

abstract type OutcomeMetric <: Metric end

abstract type InteractionReport{
    O <: ObservationMetric, 
    D <: OutcomeMetric,
    M <: MeasureSet
} <: Report end

abstract type InteractionReporter{D <: OutcomeMetric} <: Reporter end


end