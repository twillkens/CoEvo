module LinguisticPredictionGame

export LinguisticPredictionGameDomain

using .....Ecosystems.Metrics.Abstract: Metric
using .....Ecosystems.Metrics.Concrete.Outcomes.PredictionGameOutcomeMetrics: PredictionGameOutcomeMetrics
using .PredictionGameOutcomeMetrics: Control, Competitive, CooperativeMatching, CooperativeMismatching
using ...Domains.Abstract: Domain

import ...Domains.Interfaces: measure

struct LinguisticPredictionGameDomain{M <: Metric} <: Domain{M}
    outcome_metric::M
end

function LinguisticPredictionGameDomain(metric::Symbol)
    symbol_to_metric = Dict(
        :Control => Control,
        :Competitive => Competitive,
        :CooperativeMatching => CooperativeMatching,
        :CooperativeMismatching => CooperativeMismatching
    )
    LinguisticPredictionGameDomain(symbol_to_metric[metric]())
end

function measure(::LinguisticPredictionGameDomain{Control}, ::Float64)
    outcome_set = [1.0, 1.0]
    return outcome_set
end

function measure(::LinguisticPredictionGameDomain{Competitive}, distance_score::Float64)
    outcome_set = [1 - distance_score, distance_score]
    return outcome_set
end

function measure(::LinguisticPredictionGameDomain{CooperativeMatching}, distance_score::Float64)
    outcome_set = [1 - distance_score, 1 - distance_score]
    return outcome_set
end

function measure(
    ::LinguisticPredictionGameDomain{CooperativeMismatching}, distance_score::Float64
)
    outcome_set = [distance_score, distance_score]
    return outcome_set
end


end
