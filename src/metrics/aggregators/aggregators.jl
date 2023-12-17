module Aggregators

export Aggregator, BasicStatisticalAggregator, BasicQuantileAggregator, aggregate
export HigherMomentAggregator, OneSampleTTestAggregator

import ..Metrics: aggregate

using Bootstrap: bootstrap, BasicSampling, confint as bootstrap_confint
using StatsBase: mean
using StatsBase: nquantile, skewness, kurtosis, mode, mean, var, std
using HypothesisTests: OneSampleTTest, confint as hypothesis_tests_confint
using ..Metrics: Metric, Measurement, Aggregator
using ..Metrics.Common: BasicMeasurement

struct BasicStatisticalAggregator <: Aggregator end

function aggregate(
    ::BasicStatisticalAggregator, 
    base_path::String,
    measurements::Vector{<:BasicMeasurement}
)
    values = [measurement.value for measurement in measurements]
    if length(values) == 0
        measurements = [
            BasicMeasurement("$base_path/n_values", 0),
            BasicMeasurement("$base_path/sum", 0),
            BasicMeasurement("$base_path/mean", 0),
            BasicMeasurement("$base_path/var", 0),
            BasicMeasurement("$base_path/std", 0),
        ]
        return measurements
    end
    measurements = [
        BasicMeasurement("$base_path/n_values", length(values)),
        BasicMeasurement("$base_path/sum", sum(values)),
        BasicMeasurement("$base_path/mean", mean(values)),
        BasicMeasurement("$base_path/var", var(values)),
        BasicMeasurement("$base_path/std", std(values)),
    ]
    return measurements
end

struct BasicQuantileAggregator <: Aggregator end

function aggregate(
    ::BasicQuantileAggregator, 
    base_path::String,
    measurements::Vector{<:BasicMeasurement}
)
    values = [measurement.value for measurement in measurements]
    if length(values) == 0
        measurements = [
            BasicMeasurement("$base_path/minimum", 0),
            BasicMeasurement("$base_path/lower_quartile", 0),
            BasicMeasurement("$base_path/median", 0),
            BasicMeasurement("$base_path/upper_quartile", 0),
            BasicMeasurement("$base_path/maximum", 0),
        ]
        return measurements
    end
    quantiles = nquantile(values, 4)
    measurements = [
        BasicMeasurement("$base_path/minimum", quantiles[1]),
        BasicMeasurement("$base_path/lower_quartile", quantiles[2]),
        BasicMeasurement("$base_path/median", quantiles[3]),
        BasicMeasurement("$base_path/upper_quartile", quantiles[4]),
        BasicMeasurement("$base_path/maximum", quantiles[5]),
    ]
    return measurements
end

struct HigherMomentAggregator <: Aggregator end

function aggregate(
    ::HigherMomentAggregator, 
    base_path::String,
    measurements::Vector{<:BasicMeasurement}
)
    values = [measurement.value for measurement in measurements]
    measurements = [
        BasicMeasurement("$base_path/skew", skewness(values)),
        BasicMeasurement("$base_path/kurt", kurtosis(values)),
    ]
    return measurements
end

struct OneSampleTTestAggregator <: Aggregator end

function aggregate(
    ::OneSampleTTestAggregator, 
    base_path::String,
    measurements::Vector{<:BasicMeasurement}
)
    values = [measurement.value for measurement in measurements]
    loconf, hiconf = hypothesis_tests_confint(OneSampleTTest(values))
    measurements = [
        BasicMeasurement("$base_path/lower_confidence", loconf),
        BasicMeasurement("$base_path/upper_confidence", hiconf),
    ]
    return measurements
end

function aggregate(
    aggregators::Vector{<:Aggregator}, 
    base_path::String, 
    measurements::Vector{<:Measurement}
)
    aggregated_measurements = vcat([
        aggregate(aggregator, base_path, measurements) for aggregator in aggregators
    ]...)
    return aggregated_measurements
end

Base.@kwdef struct BootstrapAggregator <: Aggregator 
    n_samples::Int = 1000
    confidence_interval::Float64 = 0.95
end

function aggregate(
    aggregator::BootstrapAggregator, 
    base_path::String,
    measurements::Vector{<:BasicMeasurement}
)
    if length(measurements) == 0
        measurements = [
            BasicMeasurement("$base_path/lower_confidence", 0),
            BasicMeasurement("$base_path/upper_confidence", 0),
        ]
        return measurements
    end
    values = [measurement.value for measurement in measurements]
    bootstrap_result = bootstrap(mean, values, BasicSampling(aggregator.n_samples))
    _, lower_confidence, upper_confidence = bootstrap_confint(
        bootstrap_result, aggregator.confidence_interval
    )
    measurements = [
        BasicMeasurement("$base_path/lower_confidence", lower_confidence),
        BasicMeasurement("$base_path/upper_confidence", upper_confidence),
    ]
end


end
