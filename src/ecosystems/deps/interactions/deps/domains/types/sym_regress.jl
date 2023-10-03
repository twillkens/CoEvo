module SymbolicRegression

export SymbolicRegressionDomain

using .....Ecosystems.Metrics.Outcomes.Abstract: OutcomeMetric
using ...Domains.Abstract: Domain

Base.@kwdef struct SymbolicRegressionDomain{O <: OutcomeMetric} <: Domain{O}
    outcome_metric::O
    target_function::Function
end

end