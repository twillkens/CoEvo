
"""
    get_outcome_set(metric, A::Vector{<:Real}, B::Vector{<:Real})

Determine the outcome set scores for participants A and B based on the specified metric.

# Arguments
- `metric`: The metric determining the nature of interactions.
- `A::Vector{<:Real}`: Vector of participant A's values.
- `B::Vector{<:Real}`: Vector of participant B's values.
"""

function get_outcome_set(domain::NumbersGameDomain)
    A, B = act(domain, domain.entities[1]), act(domain, domain.entities[2])
    get_outcome_set(domain.metric, A, B)
end

function get_outcome_set(::Control, ::Vector{<:Real}, ::Vector{<:Real})
    return [1.0, 1.0]
end

function get_outcome_set(::Sum, A::Vector{<:Real}, B::Vector{<:Real})
    outcome_set = sum(A) > sum(B) ? [1.0, 0.0] : (sum(A) < sum(B) ? [0.0, 1.0] : [0.5, 0.5])
    return outcome_set
end

function get_outcome_set(::Gradient, A::Vector{<:Real}, B::Vector{<:Real})
    outcome_set = sum([v1 > v2 for (v1, v2) in zip(A, B)]) > sum([v1 < v2 for (v1, v2) in zip(A, B)]) ? [1.0, 0.0] : [0.0, 1.0]
    return outcome_set
end
 
function get_outcome_set(::Focusing, A::Vector{<:Real}, B::Vector{<:Real})
    outcome_set = A[findmax(abs.(A - B))[2]] > B[findmax(abs.(A - B))[2]] ? [1.0, 0.0] : [0.0, 1.0]
    return outcome_set
end

function get_outcome_set(::Relativism, A::Vector{<:Real}, B::Vector{<:Real})
    outcome_set = A[findmin(abs.(A - B))[2]] > B[findmin(abs.(A - B))[2]] ? [1.0, 0.0] : [0.0, 1.0]
    return outcome_set
end
