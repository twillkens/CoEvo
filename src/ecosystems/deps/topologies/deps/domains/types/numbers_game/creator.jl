module Creator

export NumbersGameDomain, NumbersGameDomainCreator

using ......Ecosystems.Species.Individuals.Phenotypes.Vectors: Vectors
using .Vectors.Abstract: VectorPhenotype
using .Vectors.Basic: BasicVectorPhenotype
using ...Abstract: Domain, DomainCreator
using ..Metrics: NumbersGameMetric, Control, Sum, Gradient, Focusing, Relativism
#using .....Ecosystems.Abstract: Metric

import ...Interfaces: next!, create_domain, is_active, refresh!, assign_entities!, get_outcomes

mutable struct NumbersGameDomain{P <: VectorPhenotype, M <: NumbersGameMetric} <: Domain
    id::String
    entities::Vector{P}
    metric::M
end

Base.@kwdef struct NumbersGameDomainCreator{
    M <: NumbersGameMetric, V <: VectorPhenotype
} <: DomainCreator
    id::String
    metric::M
    entities::Vector{V} = [BasicVectorPhenotype([0.0, 0.0]) for _ in 1:2]
end

"""
    NumbersGameDomain(metric::Symbol)

Construct a NumbersGame Domain instance using the provided metric.

# Arguments
- `metric::Symbol`: Metric type, can be one of: `:Control`, `:Sum`, `:Gradient`, `:Focusing`, or `:Relativism`.

# Throws
- `ArgumentError`: If the provided metric symbol is not recognized.
"""
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


function create_domain(domain_id::String, domain::NumbersGameDomainCreator)
    NumbersGameDomain(domain_id, domain.entities, domain.metric)
end

function is_active(::NumbersGameDomain)
    false
end

function next!(::NumbersGameDomain)
    throw(ErrorException("Cannot call `next!` on NumbersGameDomain"))
end

function refresh!(domain::NumbersGameDomain, entities::Vector{VectorPhenotype})
    NumbersGameDomain(domain.id, entities, domain.metric)
end

function assign_entities!(domain::NumbersGameDomain, phenotypes::Vector{<:VectorPhenotype})
    domain.entities = phenotypes
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
    A, B = act(domain.entities[1], nothing), act(domain, domain.entities[2], nothing)
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