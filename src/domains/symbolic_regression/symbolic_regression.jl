module SymbolicRegression

export SymbolicRegressionDomain

import ...Domains: measure

using Base: @kwdef
using ...Metrics: Metric
using ...Metrics.Evaluations: AbsoluteError
using ..Domains: Domain

@kwdef struct SymbolicRegressionDomain{M <: Metric} <: Domain{M}
    outcome_metric::M
    target_function::Function
end

function SymbolicRegressionDomain(target_function::Function)
    SymbolicRegressionDomain(AbsoluteError(), target_function)
end

function measure(::SymbolicRegressionDomain{AbsoluteError}, y::Real, y_hat::Real)
    error = [abs(y - y_hat), 0.0]
    return error
end

end