
module ContinuousPredictionGame

export ContinuousPredictionGameDomain

using .....Ecosystems.Metrics.Outcomes.Abstract: OutcomeMetric
using ...Domains.Abstract: Domain


struct ContinuousPredictionGameDomain{O <: OutcomeMetric} <: Domain{O}
    outcome_metric::O
end



end