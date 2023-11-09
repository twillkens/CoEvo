module Common

export NullMetric, RuntimeMetric, GlobalStateMetric, BasicMeasurement, BasicGroupMeasurement

using Base: @kwdef
using ...Evaluators
using ...Species
using ..Metrics: Metric, Measurement, measure, get_name


struct NullMetric <: Metric end

struct GlobalStateMetric <: Metric end

struct RuntimeMetric <: Metric end

struct BasicMeasurement{T} <: Measurement
    name::String
    value::T
end

function BasicMeasurement(metric::Metric, value::T) where T
    name = get_name(metric)
    measurement = BasicMeasurement(name, value)
    return measurement
end

struct BasicGroupMeasurement{M <: Measurement} <: Measurement
    name::String
    measurements::Vector{M}
end

function BasicGroupMeasurement(metric::Metric, measurements::Vector{M}) where M <: Measurement
    name = get_name(metric)
    measurement = BasicGroupMeasurement(name, measurements)
    return measurement
end

end