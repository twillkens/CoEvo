module NumbersGame

export NumbersGameProblem, Control, Sum, Gradient, Focusing, Relativism

using .....CoEvo: Problem, ObservationConfiguration
using ....Interactions: InteractionResult

"""
    NumbersGameMetric

Abstract type representing metrics for the numbers game.
"""
abstract type NumbersGameMetric end

# Different metrics for the numbers game.
struct Control <: NumbersGameMetric end
struct Sum <: NumbersGameMetric end
struct Gradient <: NumbersGameMetric end
struct Focusing <: NumbersGameMetric end
struct Relativism <: NumbersGameMetric end

"""
    NumbersGameProblem{M <: NumbersGameMetric} <: Problem

A problem type representing the numbers game with a specific metric.

# Fields:
- `metric::M`: Metric determining the nature of interactions.
"""
struct NumbersGameProblem{M <: NumbersGameMetric} <: Problem 
    metric::M
end

"""
    NumbersGameProblem(metric::Symbol)

Create a NumbersGameProblem with the specified metric.
"""
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

# Interaction functions to determine outcomes based on the metric of the problem.

"""
    interact(
        ::NumbersGameProblem{Control}, 
        domain_id::Int, 
        ::ObservationConfiguration, 
        id1::Int, id2::Int,
        A::Vector{<:Real}, B::Vector{<:Real}
    )

Perform an interaction for the Control metric. This function always returns 
equal scores for both participants, regardless of their inputs.

# Arguments:
- `domain_id`: Identifier for the domain.
- `id1`: Identifier for the first participant.
- `id2`: Identifier for the second participant.
- `A`: Vector of real numbers representing the state of the first participant.
- `B`: Vector of real numbers representing the state of the second participant.

# Returns:
- An `InteractionResult` with equal scores of 1.0 for both participants.
"""
function interact(
    ::NumbersGameProblem{Control}, 
    domain_id::Int, 
    ::ObservationConfiguration, 
    id1::Int, id2::Int,
    A::Vector{<:Real}, B::Vector{<:Real}
)
    InteractionResult(domain_id, [id1, id2], [1.0, 1.0])
end

# Scoring functions for various metrics.

# Always returns equal scores for both participants.
score(::Control, ::Vector{<:Real}, ::Vector{<:Real}) = [1.0, 1.0]

# Returns scores based on the sum of the vectors. The participant with the higher sum gets a score of 1.0.
score(::Sum, A::Vector{<:Real}, B::Vector{<:Real}) = sum(A) > sum(B) ? [1.0, 0.0] : (sum(A) < sum(B) ? [0.0, 1.0] : [0.5, 0.5])

# Compares each element of the vectors and gives a score to the participant that has a majority of higher elements.
score(::Gradient, A::Vector{<:Real}, B::Vector{<:Real}) = begin
    s1 = sum([v1 > v2 for (v1, v2) in zip(A, B)])
    s2 = sum([v1 < v2 for (v1, v2) in zip(A, B)])
    s1 > s2 ? [1.0, 0.0] : (s1 < s2 ? [0.0, 1.0] : [0.5, 0.5])
end

# Focuses on the maximum absolute difference between the two vectors.
score(::Focusing, A::Vector{<:Real}, B::Vector{<:Real}) = begin
    _, idx = findmax(abs.(A - B))
    if A[idx] > B[idx]
        [1.0, 0.0]
    elseif A[idx] < B[idx]
        [0.0, 1.0]
    else
        [0.5, 0.5]
    end
end

# Focuses on the minimum absolute difference between the two vectors.
score(::Relativism, A::Vector{<:Real}, B::Vector{<:Real}) = begin
    _, idx = findmin(abs.(A - B))
    if A[idx] > B[idx]
        [1.0, 0.0]
    elseif A[idx] < B[idx]
        [0.0, 1.0]
    else
        [0.5, 0.5]
    end
end

end
