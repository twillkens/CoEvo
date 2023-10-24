module NumbersGame

export NumbersGameDomain, Control, Sum, Gradient, Focusing, Relativism

import ..Domains: measure

using Base: @kwdef
using ...Metrics: Metric
using ..Domains: Domain

struct NumbersGameDomain{M <: Metric} <: Domain{M}
    outcome_metric::M
end

function outcome_decision(result::Bool)
    return result ? [1.0, 0.0] : [0.0, 1.0]
end

@kwdef struct Control <: Metric 
    name::String = "Control"
end

function measure(::NumbersGameDomain{Control}, A::Vector{<:Real}, B::Vector{<:Real})
    return [1.0, 1.0]
end

@kwdef struct Sum <: Metric 
    name::String = "Sum"
end

function measure(::NumbersGameDomain{Sum}, A::Vector{<:Real}, B::Vector{<:Real})
    sumA, sumB = sum(A), sum(B)
    return outcome_decision(sumA > sumB)
end

@kwdef struct Gradient <: Metric 
    name::Symbol = "Gradient"
end

function measure(::NumbersGameDomain{Gradient}, A::Vector{<:Real}, B::Vector{<:Real})
    compare_results = [v1 > v2 for (v1, v2) in zip(A, B)]
    return outcome_decision(sum(compare_results) > length(A) / 2)
end

@kwdef struct Focusing <: Metric 
    name::Symbol = "Focusing"
end

function measure(::NumbersGameDomain{Focusing}, A::Vector{<:Real}, B::Vector{<:Real})
    idx = findmax(abs.(A - B))[2]
    return outcome_decision(A[idx] > B[idx])
end

@kwdef struct Relativism <: Metric 
    name::Symbol = "Relativism"
end

function measure(::NumbersGameDomain{Relativism}, A::Vector{<:Real}, B::Vector{<:Real})
    idx = findmin(abs.(A - B))[2]
    return outcome_decision(A[idx] > B[idx])
end

function NumbersGameDomain(metric::Symbol)
    symbol_to_metric = Dict(
        :Control => Control,
        :Sum => Sum,
        :Gradient => Gradient,
        :Focusing => Focusing,
        :Relativism => Relativism
    )
    outcome_metric = symbol_to_metric[metric]()
    domain = NumbersGameDomain(outcome_metric)
    return domain
end

end