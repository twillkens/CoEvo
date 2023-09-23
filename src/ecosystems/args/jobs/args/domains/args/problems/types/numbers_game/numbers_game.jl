module NumbersGame

export NumbersGameProblem, Control, Sum, Gradient, Focusing, Relativism

using ......CoEvo.Abstract: Problem, ObservationConfiguration
using .....Ecosystems.Observations: OutcomeObservation, OutcomeObservationConfiguration

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


# Scoring functions for various metrics.

# Always returns equal scores for both participants.
get_outcome_set(::Control, ::Vector{<:Real}, ::Vector{<:Real}) = [1.0, 1.0]

# Returns scores based on the sum of the vectors. The participant with the higher sum gets a score of 1.0.
get_outcome_set(::Sum, A::Vector{<:Real}, B::Vector{<:Real}) = sum(A) > sum(B) ? [1.0, 0.0] : (sum(A) < sum(B) ? [0.0, 1.0] : [0.5, 0.5])

# Compares each element of the vectors and gives a score to the participant that has a majority of higher elements.
get_outcome_set(::Gradient, A::Vector{<:Real}, B::Vector{<:Real}) = begin
    s1 = sum([v1 > v2 for (v1, v2) in zip(A, B)])
    s2 = sum([v1 < v2 for (v1, v2) in zip(A, B)])
    s1 > s2 ? [1.0, 0.0] : (s1 < s2 ? [0.0, 1.0] : [0.5, 0.5])
end

# Focuses on the maximum absolute difference between the two vectors.
get_outcome_set(::Focusing, A::Vector{<:Real}, B::Vector{<:Real}) = begin
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
get_outcome_set(::Relativism, A::Vector{<:Real}, B::Vector{<:Real}) = begin
    _, idx = findmin(abs.(A - B))
    if A[idx] > B[idx]
        [1.0, 0.0]
    elseif A[idx] < B[idx]
        [0.0, 1.0]
    else
        [0.5, 0.5]
    end
end

function interact(
    problem::NumbersGameProblem, 
    domain_id::Int, 
    obs_cfg::ObservationConfiguration, 
    indiv_ids::Vector{Int},
    A::Vector{<:Real}, B::Vector{<:Real}
)
    outcome_set = get_outcome_set(problem.metric, A, B)
    obs_cfg(problem, domain_id, indiv_ids, outcome_set; A = A, B = B )
end

function OutcomeObservationConfiguration(
    ::NumbersGameProblem, 
    domain_id, 
    indiv_ids::Vector{Int}, 
    outcome_set::Vector{Float64}; 
    kwargs...
)
    return OutcomeObservation(domain_id, indiv_ids, outcome_set)
end

end
