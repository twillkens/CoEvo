module PredictionGame

export PredictionGameDomain, Control, Adversarial, Affinitive, Avoidant

import ....Interfaces: measure

using Base: @kwdef
using ....Abstract
using ....Abstract: Metric, Domain

struct PredictionGameDomain{M <: Metric} <: Domain{M}
    outcome_metric::M
end

@kwdef struct Control <: Metric
    name::String = "Control"
end

function measure(::PredictionGameDomain{Control}, ::Float64)
    outcome_set = [1.0, 1.0]
    return outcome_set
end

@kwdef struct Adversarial <: Metric
    name::String = "Adversarial"
end

function measure(::PredictionGameDomain{Adversarial}, distance_score::Float64)
    outcome_set = [1 - distance_score, distance_score]
    return outcome_set
end

@kwdef struct PredatorPrey <: Metric
    name::String = "PredatorPrey"
end

function measure(::PredictionGameDomain{PredatorPrey}, distance_score::Float64)

    #outcome_set = [1 - distance_score, distance_score]
    if distance_score > 0.5
        outcome_set = [0.0, 1.0]
    else
        outcome_set = [1.0, 0.0]
    end
    return outcome_set
end

@kwdef struct PreyPredator <: Metric
    name::String = "PreyPredator"
end

function measure(::PredictionGameDomain{PreyPredator}, distance_score::Float64)
    outcome_set = [distance_score, 1 - distance_score]
    return outcome_set
end


@kwdef struct Affinitive <: Metric
    name::String = "Affinitive"
end

function measure(::PredictionGameDomain{Affinitive}, distance_score::Float64)
    #outcome_set = [1 - distance_score, 1 - distance_score]
    if distance_score > 0.5
        outcome_set = [0.0, 0.0]
    else
        outcome_set = [1.0, 1.0]
    end
    return outcome_set
end

@kwdef struct Avoidant <: Metric
    name::String = "Avoidant"
end

function measure(::PredictionGameDomain{Avoidant}, distance_score::Float64)
    outcome_set = [distance_score, distance_score]
    return outcome_set
end

function PredictionGameDomain(metric_string::String)
    string_to_metric = Dict(
        "Control" => Control,
        "Adversarial" => Adversarial,
        "Affinitive" => Affinitive,
        "Avoidant" => Avoidant,
        "PredatorPrey" => PredatorPrey,
        "PreyPredator" => PreyPredator
    )
    metric = string_to_metric[metric_string]()
    domain = PredictionGameDomain(metric)
    return domain
end

end