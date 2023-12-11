module Evaluations

export EvaluationMetric, measure, RawFitnessEvaluationMetric, ScaledFitnessEvaluationMetric

import ..Metrics: measure

using ...Evaluators: Evaluation, get_raw_fitnesses, get_scaled_fitnesses
using ...Evaluators.ScalarFitness: ScalarFitnessEvaluation 
using ...Evaluators.NSGAII: NSGAIIEvaluation
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

function measure(::RawFitnessEvaluationMetric, evaluation::ScalarFitnessEvaluation)
    fitnesses = get_raw_fitnesses(evaluation)
    measurements = [BasicMeasurement("raw_fitness", fitness) for fitness in fitnesses]
    return measurements
end

function measure(metric::RawFitnessEvaluationMetric, evaluation::NSGAIIEvaluation)
    scalar_fitness_evaluation = evaluation.scalar_fitness_evaluation
    measurements = measure(metric, scalar_fitness_evaluation)
    return measurements
end

function measure(::ScaledFitnessEvaluationMetric, evaluation::ScalarFitnessEvaluation)
    fitnesses = get_scaled_fitnesses(evaluation)
    measurements = [BasicMeasurement("scaled_fitness", fitness) for fitness in fitnesses]
    return measurements
end

function measure(metric::ScaledFitnessEvaluationMetric, evaluation::NSGAIIEvaluation)
    scalar_fitness_evaluation = evaluation.scalar_fitness_evaluation
    measurements = measure(metric, scalar_fitness_evaluation)
    return measurements
end

end

