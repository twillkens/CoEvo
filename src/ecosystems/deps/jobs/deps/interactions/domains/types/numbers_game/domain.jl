export NumbersGameDomain, NumbersGameDomainCreator, is_active, next!, create_domain, act, refresh!

using ......Ecosystems.Species.Individuals.Phenotypes.Vectors.Abstract: VectorPhenotype
using ......Ecosystems.Species.Individuals.Phenotypes.Vectors: BasicVectorPhenotype
using ..Abstract: Domain, DomainCreator

import ..Abstract: next!, create_domain, is_active, refresh!


mutable struct NumbersGameDomain{P <: VectorPhenotype, M <: NumbersGameMetric} <: Domain
    id::String
    entities::Vector{P}
    metric::M
end

Base.@kwdef struct NumbersGameDomainCreator{M <: Metric, V <: BasicVectorPhenotype} <: DomainCreator
    id::String
    metric::M
    entities::Vector{V} = [BasicVectorPhenotype([0.0, 0.0]) for _ in 1:2]
end

function act(domain::NumbersGameDomain, entity::BasicVectorPhenotype)
    entity.values
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

function refresh!(ng::NumbersGameDomain, entities::Vector{BasicVectorPhenotype})
    NumbersGameDomain(ng.id, entities, ng.metric)
end
