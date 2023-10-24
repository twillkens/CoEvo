module NumbersGameOutcomeMetrics

export Control, Sum, Gradient
export Focusing, Relativism

using ....Metrics.Abstract: Metric

"""
    Control <: NumbersGameOutcomeMetric

Metric representing equal scoring in the numbers game.
"""

Base.@kwdef struct Control <: Metric 
    name::String = "Control"
end

struct Sum <: Metric end

struct Gradient <: Metric end

struct Focusing <: Metric end

struct Relativism <: Metric end
end