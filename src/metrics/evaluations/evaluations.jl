module Evaluations

export EvaluationMetric, FitnessEvaluationMetric, measure

using ...Evaluators: Evaluation, get_fitnesses
using ..Metrics: Metric, Measurement, Aggregator, aggregate
using ..Metrics.Common: BasicMeasurement
using ..Metrics.Aggregators: BasicStatisticalAggregator, BasicQuantileAggregator
using ..Metrics.Aggregators: OneSampleTTestAggregator, HigherMomentAggregator

abstract type EvaluationMetric <: Metric end

function measure(metric::EvaluationMetric, evaluations::Vector{<:Evaluation})
    measurements = [measure(metric, evaluation) for evaluation in evaluations]
    measurements = vcat(measurements...)
    return measurements
end

Base.@kwdef struct FitnessEvaluationMetric{A <: Aggregator} <:  EvaluationMetric
    name::String = "Fitness"
end

function measure(metric::FitnessEvaluationMetric, evaluation::Evaluation)
    fitnesses = get_fitnesses(evaluation)
    measurements = [BasicMeasurement(metric, fitness) for fitness in fitnesses]
    return measurements
end

end