module PredictionGame

export PredictionGameDomain

using .....Ecosystems.Metrics.Abstract: Metric
using .....Ecosystems.Metrics.Concrete.Outcomes.PredictionGameOutcomeMetrics: PredictionGameOutcomeMetrics
using .PredictionGameOutcomeMetrics: Control, Affinitive, Adversarial, Avoidant
using ...Domains.Abstract: Domain

import ...Domains.Interfaces: measure

struct PredictionGameDomain{M <: Metric} <: Domain{M}
    outcome_metric::M
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

function measure(::PredictionGameDomain{Control}, ::Float64)
    outcome_set = [1.0, 1.0]
    return outcome_set
end

function measure(::PredictionGameDomain{Adversarial}, distance_score::Float64)
    outcome_set = [1 - distance_score, distance_score]
    return outcome_set
end

function measure(::PredictionGameDomain{Affinitive}, distance_score::Float64)
    outcome_set = [1 - distance_score, 1 - distance_score]
    return outcome_set
end

function measure(::PredictionGameDomain{Avoidant}, distance_score::Float64)
    outcome_set = [distance_score, distance_score]
    return outcome_set
end

end