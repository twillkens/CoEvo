module Aggregators

export Aggregator, BasicFeatureAggregator, BasicQuantileAggregator, aggregate
export HigherMomentAggregator, OneSampleTTestAggregator

using StatsBase: nquantile, skewness, kurtosis, mode, mean, var, std
using HypothesisTests: OneSampleTTest, confint

using ..Metrics: Metric, Measurement, Aggregator
using ..Metrics.Common: BasicMeasurement, BasicGroupMeasurement

struct BasicFeatureAggregator <: Aggregator end

function aggregate(
    ::BasicFeatureAggregator, measurements::Vector{BasicMeasurement{R}}
) where R <: Real
    values = [measurement.value for measurement in measurements]
    measurements = [
        BasicMeasurement("n_values", length(values)),
        BasicMeasurement("sum", sum(values)),
        BasicMeasurement("mean", mean(values)),
        BasicMeasurement("var", var(values)),
        BasicMeasurement("std", std(values)),
    ]
    return measurements
end

struct BasicQuantileAggregator <: Aggregator end

function aggregate(
    ::BasicQuantileAggregator, measurements::Vector{BasicMeasurement{R}}
) where R <: Real
    values = [measurement.value for measurement in measurements]
    quantiles = nquantile(values, 4)
    measurements = [
        BasicMeasurement("minimum", quantiles[1]),
        BasicMeasurement("lower_quartile", quantiles[2]),
        BasicMeasurement("median", quantiles[3]),
        BasicMeasurement("upper_quartile", quantiles[4]),
        BasicMeasurement("maximum", quantiles[5]),
    ]
    return measurements
end

struct HigherMomentAggregator <: Aggregator end

function aggregate(
    ::HigherMomentAggregator, measurements::Vector{BasicMeasurement{R}}
) where R <: Real
    values = [measurement.value for measurement in measurements]
    measurements = [
        BasicMeasurement("skew", skewness(values)),
        BasicMeasurement("kurt", kurtosis(values)),
    ]
    return measurements
end

struct OneSampleTTestAggregator <: Aggregator end

function aggregate(
    ::OneSampleTTestAggregator, measurements::Vector{BasicMeasurement{R}}
) where R <: Real
    values = [measurement.value for measurement in measurements]
    loconf, hiconf = confint(OneSampleTTest(values))
    measurements = [
        BasicMeasurement("lower_confidence", loconf),
        BasicMeasurement("upper_confidence", hiconf),
    ]
    return measurements
end

end
