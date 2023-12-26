export get_bootstrapped_confidence_intervals, get_basic_statistics, get_quantiles
export get_proportion, measure_shannon_entropy, get_aggregate_measurements
export DEFAULT_QUANTILES, DEFAULT_BASIC_STATISTICS, DEFAULT_BOOTSTRAPPED_CONFIDENCE_INTERVALS
export N_BOOTSTRAP_SAMPLES, DEFAULT_CONFIDENCE

using Bootstrap: bootstrap, BasicSampling, BasicConfInt, confint as bootstrap_confint
using StatsBase: nquantile, skewness, kurtosis, mode, mean, var, std

const DEFAULT_QUANTILES = Dict(
        "minimum" => 0,
        "lower_quartile" => 0,
        "median" => 0,
        "upper_quartile" => 0,
        "maximum" => 0,
)

const DEFAULT_BASIC_STATISTICS = Dict(
        "n_values" => 0,
        "sum" => 0,
        "mean" => 0,
        "var" => 0,
        "std" => 0,
)

const DEFAULT_BOOTSTRAPPED_CONFIDENCE_INTERVALS = Dict(
        "lower_confidence" => 0,
        "upper_confidence" => 0,
)
const N_BOOTSTRAP_SAMPLES = 1000

const DEFAULT_CONFIDENCE = 0.95

function get_bootstrapped_confidence_intervals(values::Vector{Float64})
    if length(values) == 0
        return DEFAULT_BOOTSTRAPPED_CONFIDENCE_INTERVALS
    end
    bootstrap_result = bootstrap(mean, values, BasicSampling(1000))
    _, lower_confidence, upper_confidence = first(bootstrap_confint(
        bootstrap_result, BasicConfInt(DEFAULT_CONFIDENCE)
    ))
    confidence_intervals = Dict(
        "lower_confidence" => lower_confidence,
        "upper_confidence" => upper_confidence,
    )
    return confidence_intervals
end


function get_basic_statistics(values::Vector{Float64})
    if length(values) == 0
        return DEFAULT_BASIC_STATISTICS
    end
    statistics = Dict(
        "n_values" => length(values),
        "sum" => sum(values),
        "mean" => mean(values),
        "var" => var(values),
        "std" => std(values),
    )
    return statistics
end

function get_quantiles(values::Vector{Float64})
    if length(values) == 0
        return DEFAULT_QUANTILES
    end
    quantiles = nquantile(values, 4)
    quantiles = Dict(
        "minimum" => quantiles[1],
        "lower_quartile" => quantiles[2],
        "median" => quantiles[3],
        "upper_quartile" => quantiles[4],
        "maximum" => quantiles[5],
    )
    return quantiles
end

function get_proportion(values::Vector{T}, value::T) where T
    if length(values) == 0
        return 0
    end
    proportion = length(filter(v -> v == value, values)) / length(values)
    return proportion
end

function measure_shannon_entropy(values::Vector{T}) where T
    if length(values) == 0
        return 0
    end
    shannon_entropy = 0
    for value in Set(values)
        proportion = get_proportion(values, value)
        shannon_entropy -= proportion * log(2, proportion)
    end
    return shannon_entropy
end

function get_aggregate_measurements(values::Vector{Float64})
    basic_statistics = get_basic_statistics(values)
    quantiles = get_quantiles(values)
    bootstrapped_confidence_intervals = get_bootstrapped_confidence_intervals(values)
    measurements = merge(basic_statistics, quantiles, bootstrapped_confidence_intervals)
    return measurements
end

get_aggregate_measurements(values::Vector{<:Real}) = get_aggregate_measurements(float.(values))