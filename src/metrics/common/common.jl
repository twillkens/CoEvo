module Common

export NullMetric, RuntimeMetric, GlobalStateMetric, BasicMeasurement

using Base: @kwdef
using ...Evaluators
using ...Species
using ..Metrics: Metric, Measurement, measure, get_name

struct NullMetric <: Metric end

Base.@kwdef struct GlobalStateMetric <: Metric 
    name::String = "global_state"
    to_print::Union{String, Vector{String}} = "all"
    to_save::Union{String, Vector{String}} = "all"
end

Base.@kwdef struct RuntimeMetric <: Metric 
    name::String = "runtime"
    to_print::Union{String, Vector{String}} = "all"
    to_save::Union{String, Vector{String}} = "none"
end

struct BasicMeasurement{T} <: Measurement
    name::String
    value::T
end

function BasicMeasurement(metric::Metric, value::Any)
    name = get_name(metric)
    measurement = BasicMeasurement(name, value)
    return measurement
end

function BasicMeasurement(value::Any)
    measurement = BasicMeasurement("", value)
    return measurement
end

end