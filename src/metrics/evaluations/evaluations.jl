module Evaluations

using ...Evaluators: Evaluation
using ..Metrics: Metric, Measurement, Aggregator, aggregate
using ..Metrics.Common: BasicMeasurement, BasicGroupMeasurement

abstract type EvaluationMetric <: Metric end

function measure(metric::EvaluationMetric, evaluations::Vector{<:Evaluation})
    measurements = [measure(metric, evaluation) for evaluation in evaluations]
    measurement = BasicGroupMeasurement(metric, measurements)
    return measurement
end

Base.@kwdef struct FitnessEvaluationMetric{A <: Aggregator} <:  EvaluationMetric
    name::String = "Fitness"
    aggregators::Vector{A} = [
        BasicFeatureAggregator(),
        BasicQuantileAggregator(),
        OneSampleTTestAggregator(),
        HigherMomentAggregator()
    ]
end

function measure(metric::FitnessEvaluationMetric, evaluation::Evaluation)
    fitnesses = get_fitnesses(evaluation)
    measurements = [BasicMeasurement(metric, fitness) for fitness in fitnesses]
    aggregated_measurements = [
        aggregate(aggregator, measurements) for aggregator in metric.aggregators
    ]
    group_measurement = BasicGroupMeasurement(
        name = evaluation.species_id,
        measurements = aggregated_measurements
    )
    return group_measurement
end

end