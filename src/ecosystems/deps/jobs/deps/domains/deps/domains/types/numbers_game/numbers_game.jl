module NumbersGame

export NumbersGameSetting

using ......CoEvo.Abstract: Problem, ObservationCreator, Phenotype
using .....Ecosystems.Observations: OutcomeObservation, OutcomeObservationCreator

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
    NumbersGameSetting{M <: NumbersGameMetric} <: Problem

A domain setting for the numbers game with a specific metric.

# Fields:
- `metric::M`: Metric determining the nature of interactions.
"""
struct NumbersGameSetting{M <: NumbersGameMetric} <: Setting 
    metric::M
end

"""
    NumbersGameSetting(metric::Symbol)

Construct a NumbersGame Setting instance using the provided metric.

# Arguments
- `metric::Symbol`: Metric type, can be one of: `:Control`, `:Sum`, `:Gradient`, `:Focusing`, or `:Relativism`.

# Throws
- `ArgumentError`: If the provided metric symbol is not recognized.
"""
function NumbersGameSetting(metric::Symbol)
    symbol_to_metric = Dict(
        :Control => Control,
        :Sum => Sum,
        :Gradient => Gradient,
        :Focusing => Focusing,
        :Relativism => Relativism
    )
    NumbersGameSetting(symbol_to_metric[metric]())
end

struct NumbersGameDomain{P <: VectorPhenotype, M <: NumbersGameMetric} <: Domain
    id::String
    entities::Vector{P}
    metric::M
end

function create_domain(domain_id::String, setting::NumbersGameSetting)
    entities = [BasicVectorPhenotype([0.0, 0.0]) for _ in 1:2]
    NumbersGameDomain(domain_id, entities, setting.metric)
end

function is_active(::NumbersGameDomain)
    false
end

function next!(::NumbersGameDomain)
    throw(ErrorException("Cannot call `next!` on NumbersGameDomain"))
end


function observe!(observer::MaximumSumObserver, domain::NumbersGameDomain)
    observer.sum = maximum([sum(entity) for entity in domain.entities])
end


"""
    get_outcome_set(metric, A::Vector{<:Real}, B::Vector{<:Real})

Determine the outcome set scores for participants A and B based on the specified metric.

# Arguments
- `metric`: The metric determining the nature of interactions.
- `A::Vector{<:Real}`: Vector of participant A's values.
- `B::Vector{<:Real}`: Vector of participant B's values.
"""

function get_outcome_set(domain::NumbersGameDomain)
    A, B = act(domain.entities[1]), act(domain.entities[2])
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

end
