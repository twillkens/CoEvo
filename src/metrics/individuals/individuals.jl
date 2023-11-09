module Individuals

using ...Species: AbstractSpecies, get_individuals
using ..Metrics.Species: SpeciesMetric
using ..Metrics: Metric, Measurement, Aggregator, aggregate
using ..Metrics.Common: BasicGroupMeasurement

abstract type IndividualMetric <: SpeciesMetric end

function measure(metric::IndividualMetric, species::AbstractSpecies)
    individuals = get_individuals(species)
    measurements = measure(metric, individuals)
    aggregated_measurements = vcat(
        [aggregate(aggregator, measurements) for aggregator in metric.aggregators]...
    )
    measurement = BasicGroupMeasurement(species.id, aggregated_measurements)
    return measurement
end

end