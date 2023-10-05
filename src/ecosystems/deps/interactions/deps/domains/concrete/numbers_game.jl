module NumbersGame

export NumbersGameDomain, measure

using .....Ecosystems.Metrics.Abstract: Metric
using .....Ecosystems.Metrics.Concrete.Outcomes.NumbersGameOutcomeMetrics: NumbersGameOutcomeMetrics
using .NumbersGameOutcomeMetrics: Control, Sum, Gradient, Focusing, Relativism
using ...Domains.Abstract: Domain

import ...Domains.Interfaces: measure

struct NumbersGameDomain{M <: Metric} <: Domain{M}
    outcome_metric::M
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

function outcome_decision(result::Bool)
    return result ? [1.0, 0.0] : [0.0, 1.0]
end

function measure(::NumbersGameDomain{Control}, A::Vector{<:Real}, B::Vector{<:Real})
    return [1.0, 1.0]
end

function measure(::NumbersGameDomain{Sum}, A::Vector{<:Real}, B::Vector{<:Real})
    sumA, sumB = sum(A), sum(B)
    return outcome_decision(sumA > sumB)
end

function measure(::NumbersGameDomain{Gradient}, A::Vector{<:Real}, B::Vector{<:Real})
    compare_results = [v1 > v2 for (v1, v2) in zip(A, B)]
    return outcome_decision(sum(compare_results) > length(A) / 2)
end

function measure(::NumbersGameDomain{Focusing}, A::Vector{<:Real}, B::Vector{<:Real})
    idx = findmax(abs.(A - B))[2]
    return outcome_decision(A[idx] > B[idx])
end


function measure(::NumbersGameDomain{Relativism}, A::Vector{<:Real}, B::Vector{<:Real})
    idx = findmin(abs.(A - B))[2]
    return outcome_decision(A[idx] > B[idx])
end

"""
    NumbersGameEnvironment{M <: NumbersGameOutcomeMetric} <: Problem

A environment environment for the numbers game with a specific metric.

# Fields:
- `metric::M`: Metric determining the nature of interactions.
"""

end