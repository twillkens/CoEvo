module Evaluations

export EvaluationMetric, measure, RawFitnessEvaluationMetric, ScaledFitnessEvaluationMetric

import ..Metrics: measure

using ...Evaluators: Evaluation, get_raw_fitnesses, get_scaled_fitnesses
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

Base.@kwdef struct RawFitnessEvaluationMetric <:  EvaluationMetric
    name::String = "raw_fitness"
end

Base.@kwdef struct ScaledFitnessEvaluationMetric <:  EvaluationMetric
    name::String = "scaled_fitness"
end

function measure(::RawFitnessEvaluationMetric, evaluation::Evaluation)
    fitnesses = get_raw_fitnesses(evaluation)
    measurements = [BasicMeasurement("raw_fitness", fitness) for fitness in fitnesses]
    return measurements
end

function measure(::ScaledFitnessEvaluationMetric, evaluation::Evaluation)
    fitnesses = get_scaled_fitnesses(evaluation)
    measurements = [BasicMeasurement("scaled_fitness", fitness) for fitness in fitnesses]
    return measurements
end

end

