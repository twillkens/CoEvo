module NumbersGame

export NumbersGameProblem, Control, Sum, Gradient, Focusing, Relativism, interact

using ......CoEvo.Abstract: Problem, ObservationConfiguration
using .....Ecosystems.Observations: OutcomeObservation, OutcomeObservationConfiguration

"""
    NumbersGameMetric

Abstract type representing metrics for the numbers game.
"""
abstract type NumbersGameMetric end

"""
    Control <: NumbersGameMetric

Metric representing equal scoring in the numbers game.
"""
struct Control <: NumbersGameMetric end

"""
    Sum <: NumbersGameMetric

Metric for the numbers game where scoring is based on the sum of vector values.
"""
struct Sum <: NumbersGameMetric end

"""
    Gradient <: NumbersGameMetric

Metric comparing each element of vectors in the numbers game and scoring based on majority of higher elements.
"""
struct Gradient <: NumbersGameMetric end

"""
    Focusing <: NumbersGameMetric

Metric for the numbers game that scores based on the maximum absolute difference between two vectors.
"""
struct Focusing <: NumbersGameMetric end

"""
    Relativism <: NumbersGameMetric

Metric for the numbers game focusing on the minimum absolute difference between two vectors.
"""
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

Construct a NumbersGameProblem instance using the provided metric.

# Arguments
- `metric::Symbol`: Metric type, can be one of: `:Control`, `:Sum`, `:Gradient`, `:Focusing`, or `:Relativism`.

# Throws
- `ArgumentError`: If the provided metric symbol is not recognized.
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

"""
    get_outcome_set(metric, A::Vector{<:Real}, B::Vector{<:Real})

Determine the outcome set scores for participants A and B based on the specified metric.

# Arguments
- `metric`: The metric determining the nature of interactions.
- `A::Vector{<:Real}`: Vector of participant A's values.
- `B::Vector{<:Real}`: Vector of participant B's values.
"""
get_outcome_set(::Control, ::Vector{<:Real}, ::Vector{<:Real}) = [1.0, 1.0]
get_outcome_set(::Sum, A::Vector{<:Real}, B::Vector{<:Real}) = sum(A) > sum(B) ? [1.0, 0.0] : (sum(A) < sum(B) ? [0.0, 1.0] : [0.5, 0.5])
get_outcome_set(::Gradient, A::Vector{<:Real}, B::Vector{<:Real}) = sum([v1 > v2 for (v1, v2) in zip(A, B)]) > sum([v1 < v2 for (v1, v2) in zip(A, B)]) ? [1.0, 0.0] : [0.0, 1.0]
get_outcome_set(::Focusing, A::Vector{<:Real}, B::Vector{<:Real}) = A[findmax(abs.(A - B))[2]] > B[findmax(abs.(A - B))[2]] ? [1.0, 0.0] : [0.0, 1.0]
get_outcome_set(::Relativism, A::Vector{<:Real}, B::Vector{<:Real}) = A[findmin(abs.(A - B))[2]] > B[findmin(abs.(A - B))[2]] ? [1.0, 0.0] : [0.0, 1.0]

"""
    interact(problem::NumbersGameProblem, dom_id::String, obs_cfg::ObservationConfiguration, indiv_ids::Vector{Int}, A::Vector{<:Real}, B::Vector{<:Real})

Interact function to determine outcomes based on the metric of the problem and create an 
observation configuration.

# Arguments
- `problem::NumbersGameProblem`: The Numbers Game problem instance.
- `dom_id::String`: Domain ID.
- `obs_cfg::ObservationConfiguration`: Observation configuration.
- `indiv_ids::Vector{Int}`: Vector of individual IDs.
- `A::Vector{<:Real}`: Vector of participant A's values.
- `B::Vector{<:Real}`: Vector of participant B's values.
"""
function interact(
    problem::NumbersGameProblem, 
    dom_id::String, 
    obs_cfg::ObservationConfiguration, 
    indiv_ids::Vector{Int},
    A::Vector{<:Real}, B::Vector{<:Real}
)
    outcome_set = get_outcome_set(problem.metric, A, B)
    obs_cfg(problem, dom_id, indiv_ids, outcome_set; A = A, B = B )
end

end
