module NumbersGame

export NumbersGameProblem, Control, Sum, Gradient, Focusing, Relativism

using .....CoEvo: Problem, ObservationConfiguration
using ....Interactions: InteractionResult

abstract type NumbersGameMetric end

struct Control <: NumbersGameMetric end

struct Sum <: NumbersGameMetric end

struct Gradient <: NumbersGameMetric end

struct Focusing <: NumbersGameMetric end

struct Relativism <: NumbersGameMetric end

struct NumbersGameProblem{M <: NumbersGameMetric} <: Problem 
    metric::M
end

function NumbersGameProblem(metric::Symbol)
    if metric == :Control
        return NumbersGameProblem(Control())
    elseif metric == :Sum
        return NumbersGameProblem(Sum())
    elseif metric == :Gradient
        return NumbersGameProblem(Gradient())
    elseif metric == :Focusing
        return NumbersGameProblem(Focusing())
    elseif metric == :Relativism
        return NumbersGameProblem(Relativism())
    else
        throw(ArgumentError("Unknown metric: $metric"))
    end
end

function interact(
    ::NumbersGameProblem{Control}, 
    domain_id::Int, 
    ::ObservationConfiguration, 
    id1::Int, id2::Int,
    A::Vector{<:Real}, B::Vector{<:Real}
)
    InteractionResult(domain_id, [id1, id2], [1.0, 1.0])
end

score(::Control, ::Vector{<:Real}, ::Vector{<:Real}) = [1.0, 1.0]

function score(::Sum, A::Vector{<:Real}, B::Vector{<:Real}) 
    if sum(A) > sum(B)
        return [1.0, 0.0]
    elseif sum(A) < sum(B)
        return [0.0, 1.0]
    else
        return [0.5, 0.5]
    end
end

function score(::Gradient, A::Vector{<:Real}, B::Vector{<:Real}) 
    s1 = sum([v1 > v2 for (v1, v2) in zip(A, B)])
    s2 = sum([v1 < v2 for (v1, v2) in zip(A, B)])
    if s1 > s2
        return [1.0, 0.0]
    elseif s1 < s2
        return [0.0, 1.0]
    else
        return [0.5, 0.5]
    end
end
    
function score(::Focusing, A::Vector{<:Real}, B::Vector{<:Real}) 
    _, idx = findmax([abs(x1 - x2) for (x1, x2) in zip(A.vec, B.vec)])
    Float64[A.vec[idx] > B.vec[idx], B.vec[idx] > A.vec[idx]]
end

function score(::Relativism, A::Vector{<:Real}, B::Vector{<:Real}) 
    _, idx = findmin([abs(x1 - x2) for (x1, x2) in zip(A.vec, B.vec)])
    if A.vec[idx] > B.vec[idx]
        return [1.0, 0.0]
    elseif A.vec[idx] < B.vec[idx]
        return [0.0, 1.0]
    else
        return [0.5, 0.5]
    end
end

end