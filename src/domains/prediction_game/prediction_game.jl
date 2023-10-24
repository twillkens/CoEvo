module PredictionGame

export PredictionGameDomain, Control, Adversarial, Affinitive, Avoidant

import ..Domains.Interfaces: measure

using Base: @kwdef
using ..Domains.Abstract: OutcomeMetric, Domain

struct PredictionGameDomain{M <: OutcomeMetric} <: Domain{M}
    outcome_metric::M
end

@kwdef struct Control <: OutcomeMetric
    name::String = "Control"
end

function measure(::PredictionGameDomain{Control}, ::Float64)
    outcome_set = [1.0, 1.0]
    return outcome_set
end

@kwdef struct Adversarial <: OutcomeMetric
    name::String = "Adversarial"
end

function measure(::PredictionGameDomain{Adversarial}, distance_score::Float64)
    outcome_set = [1 - distance_score, distance_score]
    return outcome_set
end

@kwdef struct Affinitive <: OutcomeMetric
    name::String = "Affinitive"
end

function measure(::PredictionGameDomain{Affinitive}, distance_score::Float64)
    outcome_set = [1 - distance_score, 1 - distance_score]
    return outcome_set
end

@kwdef struct Avoidant <: OutcomeMetric
    name::String = "Avoidant"
end

function measure(::PredictionGameDomain{Avoidant}, distance_score::Float64)
    outcome_set = [distance_score, distance_score]
    return outcome_set
end

function PredictionGameDomain(metric::Symbol)
    symbol_to_metric = Dict(
        :Control => Control,
        :Adversarial => Adversarial,
        :Affinitive => Affinitive,
        :Avoidant => Avoidant,
    )
    metric = symbol_to_metric[metric]()
    domain = PredictionGameDomain(metric)
    return domain
end

end