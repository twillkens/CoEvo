
module NumbersGame

export NumbersGameDomain

using .....Ecosystems.Metrics.Outcome.Types.NumbersGame: NumbersGame as NumbersGameMetrics
using .NumbersGameMetrics: NumbersGameMetric, Control, Sum, Gradient, Focusing, Relativism
using ...Domains.Abstract: Domain


struct NumbersGameDomain{O <: NumbersGameMetric} <: Domain{O}
    outcome_metric::O
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