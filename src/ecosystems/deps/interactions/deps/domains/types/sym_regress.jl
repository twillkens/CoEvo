module SymbolicRegression

Base.@kwdef struct SymbolicRegressionDomain{O <: OutcomeMetric} <: Domain{O}
    outcome_metric::O
    func::Function
end

function NumbersGameDomain(metric::Symbol)
    symbol_to_metric = Dict(
        :Control => Control,
        :Sum => Sum,
        :Gradient => Gradient,
        :Focusing => Focusing,
        :Relativism => Relativism
    )
    NumbersGameDomain(symbol_to_metric[metric]())
end
end