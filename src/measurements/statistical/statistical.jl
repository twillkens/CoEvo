module Statistical

export BasicStatisticalMeasurement, GroupStatisticalMeasurement, extract_stat_features

using StatsBase: nquantile, skewness, kurtosis, mode, mean, var, std
using HypothesisTests: OneSampleTTest, confint

using ..Measurements: Measurement

"""
    StatisticalFeatureSet

A structured type that captures a broad range of statistical features from a given data vector.

# Fields
- `n_samples`: The number of data elements.
- `sum`: The total sum of the data elements.
- `upper_confidence`: The upper confidence interval for the mean.
- `mean`: The arithmetic mean of the data.
- `lower_confidence`: The lower confidence interval for the mean.
- `variance`: The variance of the data.
- `std`: The standard deviation of the data.
- `minimum`: The smallest value in the data.
- `lower_quartile`: The 25th percentile.
- `median`: The median or 50th percentile.
- `upper_quartile`: The 75th percentile.
- `maximum`: The largest value in the data.
- `skew`: The skewness of the data.
- `kurt`: The kurtosis of the data.
- `mod`: The mode of the data.

# Constructors
This type can be constructed from both vector and tuple data inputs.
"""
Base.@kwdef struct BasicStatisticalMeasurement <: Measurement
    n_samples::Int = 0
    sum::Float64 = 0.0
    upper_confidence::Float64 = 0.0
    mean::Float64 = 0.0
    lower_confidence::Float64 = 0.0
    variance::Float64 = 0.0
    std::Float64 = 0.0
    minimum::Float64 = 0.0
    lower_quartile::Float64 = 0.0
    median::Float64 = 0.0
    upper_quartile::Float64 = 0.0
    maximum::Float64 = 0.0
    skew::Float64 = 0.0
    kurt::Float64 = 0.0
    mode::Real = 0.0
end

struct GroupStatisticalMeasurement <: Measurement
    measurements::Dict{String, BasicStatisticalMeasurement}
end

function BasicStatisticalMeasurement(vec::Vector{<:Real}, n_round::Int=2)
    if isempty(vec) || length(vec) == 1
        return BasicStatisticalMeasurement()
    end

    quantiles = nquantile(vec, 4)
    loconf, hiconf = confint(OneSampleTTest(vec))

    # Use the round function on each feature to round to the specified number of digits
    return BasicStatisticalMeasurement(
        n_samples = length(vec),
        sum = round(sum(vec), digits = n_round),
        lower_confidence = round(loconf, digits = n_round),
        mean = round(mean(vec), digits = n_round),
        upper_confidence = round(hiconf, digits = n_round),
        variance = round(var(vec), digits = n_round),
        std = round(std(vec), digits = n_round),
        minimum = round(quantiles[1], digits = n_round),
        lower_quartile = round(quantiles[2], digits = n_round),
        median = round(quantiles[3], digits = n_round),
        upper_quartile = round(quantiles[4], digits = n_round),
        maximum = round(quantiles[5], digits = n_round),
        skew = round(skewness(vec), digits = n_round),
        kurt = round(kurtosis(vec), digits = n_round),
        mode = round(mode(vec), digits = n_round),
    )
end

"""
    extract_stat_features(sf::StatisticalFeatureSet, features::Vector{Symbol})

Extracts specified statistical features from a `StatisticalFeatureSet` object.

# Arguments
- `sf`: A `StatisticalFeatureSet` object.
- `features`: A list of symbols indicating the features to extract.

# Returns
- A dictionary mapping feature names (as strings) to their values.

# Throws
- Throws an `ArgumentError` if any requested feature is not a real number in the `BasicStatisticalMeasurement` object.
"""
function extract_stat_features(
    stat_features::BasicStatisticalMeasurement, features::Vector{Symbol}
)
    feature_dict = Dict{String, Float64}()
    for feature in features
        val = getfield(stat_features, feature)
        if isa(val, Real)  # Ensure the value is a real number (Float64 or another subtype)
            feature_dict[string(feature)] = Float64(val)
        else
            throw(ArgumentError("Requested feature $feature is not a Real number in the BasicStatisticalMeasureSetet object."))
        end
    end
    return feature_dict
end

end
