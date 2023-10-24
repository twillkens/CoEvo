module LinguisticPredictionGame

export LinguisticPredictionGameDomain

using .....Ecosystems.Metrics.Abstract: Metric
using .....Ecosystems.Metrics.Concrete.Outcomes.PredictionGameOutcomeMetrics: PredictionGameOutcomeMetrics
using .PredictionGameOutcomeMetrics: Control, Adversarial, Affinitive, Avoidant
using ...Domains.Abstract: Domain

import ...Domains.Interfaces: measure

struct LinguisticPredictionGameDomain{M <: Metric} <: Domain{M}
    outcome_metric::M
end

function LinguisticPredictionGameDomain(metric::Symbol)
    symbol_to_metric = Dict(
        :Control => Control,
        :Adversarial => Adversarial,
        :Affinitive => Affinitive,
        :Avoidant => Avoidant
    )
    LinguisticPredictionGameDomain(symbol_to_metric[metric]())
end

function measure(::LinguisticPredictionGameDomain{Control}, ::Float64)
    outcome_set = [1.0, 1.0]
    return outcome_set
end

function measure(::LinguisticPredictionGameDomain{Adversarial}, distance_score::Float64)
    outcome_set = [1 - distance_score, distance_score]
    return outcome_set
end

function measure(::LinguisticPredictionGameDomain{Affinitive}, distance_score::Float64)
    outcome_set = [1 - distance_score, 1 - distance_score]
    return outcome_set
end

function measure(
    ::LinguisticPredictionGameDomain{Avoidant}, distance_score::Float64
)
    outcome_set = [distance_score, distance_score]
    return outcome_set
end

end
