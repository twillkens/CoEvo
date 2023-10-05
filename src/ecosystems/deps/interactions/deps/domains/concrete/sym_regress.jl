module SymbolicRegression

export SymbolicRegressionDomain

using .....Ecosystems.Metrics.Abstract: Metric
using .....Ecosystems.Metrics.Concrete.Common: AbsoluteError
using ...Domains.Abstract: Domain

import ...Domains.Interfaces: measure

Base.@kwdef struct SymbolicRegressionDomain{M <: Metric} <: Domain{M}
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