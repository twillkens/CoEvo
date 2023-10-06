module CollisionGame

export CollisionGameDomain

using .....Ecosystems.Metrics.Abstract: Metric
using .....Ecosystems.Metrics.Concrete.Outcomes.CollisionGameOutcomeMetrics: CollisionGameOutcomeMetrics
using .CollisionGameOutcomeMetrics: Control, Affinitive, Adversarial, Avoidant
using ...Domains.Abstract: Domain

import ...Domains.Interfaces: measure

struct CollisionGameDomain{M <: Metric} <: Domain{M}
    outcome_metric::M
end

function CollisionGameDomain(metric::Symbol)
    symbol_to_metric = Dict(
        :Control => Control,
        :Avoidant => Avoidant,
        :Affinitive => Affinitive,
        :Adversarial => Adversarial
    )
    CollisionGameDomain(symbol_to_metric[metric]())
end

function measure(::CollisionGameDomain{Control}, ::Bool)
    outcome_set = [1.0, 1.0]
    return outcome_set
end

function measure(::CollisionGameDomain{Adversarial}, have_collided::Bool)
    outcome_set = have_collided ? [1.0, 0.0] : [0.0, 1.0]
    return outcome_set
end

function measure(::CollisionGameDomain{Affinitive}, have_collided::Bool)
    outcome_set = have_collided ? [1.0, 1.0] : [0.0, 0.0]
    return outcome_set
end

function measure(::CollisionGameDomain{Avoidant}, have_collided::Bool)
    outcome_set = have_collided ? [0.0, 0.0] : [1.0, 1.0] 
    return outcome_set
end

end
