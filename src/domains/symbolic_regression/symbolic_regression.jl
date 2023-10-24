module SymbolicRegression

export SymbolicRegressionDomain

import ...Metrics.Interfaces: measure

using Base: @kwdef
using ...Metrics.Abstract: Metric
using ..Domains.Abstract: Domain


@kwdef struct SymbolicRegressionDomain{O <: OutcomeMetric} <: Domain{O}
    outcome_metric::O
    target_function::Function
end

@kwdef struct AbsoluteError <: OutcomeMetric
    name::String = "AbsoluteError"
end

function SymbolicRegressionDomain(target_function::Function)
    SymbolicRegressionDomain(AbsoluteError(), target_function)
end

function measure(::SymbolicRegressionDomain{AbsoluteError}, y::Real, y_hat::Real)
    error = [abs(y - y_hat), 0.0]
    return error
end

end