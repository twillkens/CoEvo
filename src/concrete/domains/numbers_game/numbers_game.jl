module NumbersGame

export NumbersGameDomain, Control, Sum, Gradient, Focusing, Relativism

import ....Interfaces: measure

using Base: @kwdef
using ....Abstract: Metric, Domain

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
    name::String = "Gradient"
end

function measure(::NumbersGameDomain{Gradient}, A::Vector{<:Real}, B::Vector{<:Real})
    compare_results = [v1 > v2 for (v1, v2) in zip(A, B)]
    return outcome_decision(sum(compare_results) > length(A) / 2)
end

@kwdef struct Focusing <: Metric 
    name::String = "Focusing"
end

function measure(::NumbersGameDomain{Focusing}, A::Vector{<:Real}, B::Vector{<:Real})
    idx = findmax(abs.(A - B))[2]
    return outcome_decision(A[idx] > B[idx])
end

@kwdef struct Relativism <: Metric 
    name::String = "Relativism"
end

function measure(::NumbersGameDomain{Relativism}, A::Vector{<:Real}, B::Vector{<:Real})
    idx = findmin(abs.(A - B))[2]
    return outcome_decision(A[idx] > B[idx])
end

@kwdef struct CompareOnAll <: Metric
    name::String = "CompareOnAll"
end

function measure(::NumbersGameDomain{CompareOnAll}, A::Vector{<:Real}, B::Vector{<:Real})
    compare_results = [v1 >= v2 for (v1, v2) in zip(A, B)]
    test_passed = all(compare_results) ? 1.0 : 0.0
    return [test_passed, 1 - test_passed]
end

@kwdef struct CompareOnAllSymmetric <: Metric
    name::String = "CompareOnAllSymmetric"
end

function measure(::NumbersGameDomain{CompareOnAllSymmetric}, A::Vector{<:Real}, B::Vector{<:Real})
    compare_results_A = [v1 >= v2 for (v1, v2) in zip(A, B)]
    test_passed_A = all(compare_results_A) ? 1.0 : 0.0
    compare_results_B = [v1 >= v2 for (v1, v2) in zip(B, A)]
    test_passed_B = all(compare_results_B) ? 1.0 : 0.0
    return [test_passed_A, test_passed_B]
end

@kwdef struct CompareOnOne <: Metric
    name::String = "CompareOnOne"
end

function measure(::NumbersGameDomain{CompareOnOne}, A::Vector{<:Real}, B::Vector{<:Real})
    largest_dimension_B = findmax(B)[2]
    test_passed = A[largest_dimension_B] >= B[largest_dimension_B] ? 1.0 : 0.0
    return [test_passed, 1 - test_passed]
end

@kwdef struct CompareOnOneSymmetric <: Metric
    name::String = "CompareOnOneSymmetric"
end

function measure(::NumbersGameDomain{CompareOnOneSymmetric}, A::Vector{<:Real}, B::Vector{<:Real})
    largest_dimension_B = findmax(B)[2]
    test_passed_A = A[largest_dimension_B] >= B[largest_dimension_B] ? 1.0 : 0.0
    largest_dimension_A = findmax(A)[2]
    test_passed_B = B[largest_dimension_A] >= A[largest_dimension_A] ? 1.0 : 0.0
    return [test_passed_A, test_passed_B]
end

function NumbersGameDomain(metric_string::String)
    string_to_metric = Dict(
        "Control" => Control,
        "Sum" => Sum,
        "Gradient" => Gradient,
        "Focusing" => Focusing,
        "Relativism" => Relativism,
        "CompareOnAll" => CompareOnAll,
        "CompareOnAllSymmetric" => CompareOnAllSymmetric,
        "CompareOnOne" => CompareOnOne,
        "CompareOnOneSymmetric" => CompareOnOneSymmetric
    )
    outcome_metric = string_to_metric[metric_string]()
    domain = NumbersGameDomain(outcome_metric)
    return domain
end

end