module ContinuousPredictionGame

export get_outcome_set

using ...Environments.Types.Tape: TapeEnvironment
using ....Interactions.Domains.Types.ContinuousPredictionGame: ContinuousPredictionGameDomain
using ....Metrics.Outcomes.Types.ContinuousPredictionGame: Control
using ....Metrics.Outcomes.Types.ContinuousPredictionGame: Competitive
using ....Metrics.Outcomes.Types.ContinuousPredictionGame: CooperativeMatching
using ....Metrics.Outcomes.Types.ContinuousPredictionGame: CooperativeMismatching
using ....Species.Phenotypes.Abstract: Phenotype
using ....Species.Phenotypes.Interfaces: act!

import ....Interactions.Environments.Interfaces: get_outcome_set, next!, is_active

function radianshift(x::Real)
    x - (floor(x / 2π) * 2π)
end

function next!(
    environment::TapeEnvironment{D, <:Phenotype}
) where {D <: ContinuousPredictionGameDomain}
    a1, a2 = environment.phenotypes
    tape1, tape2 = environment.tape1, environment.tape2
    move1, move2 = act!(a1, tape2), act!(a2, tape1)
    environment.pos1 = radianshift(environment.pos1 + move1)
    environment.pos2 = radianshift(environment.pos2 + move2)
    diff1 = radianshift(environment.pos2 - environment.pos1)
    diff2 = radianshift(environment.pos1 - environment.pos2)
    push!(tape1, diff1)
    push!(tape2, diff2)
end

function is_active(
    environment::TapeEnvironment{D, <:Phenotype}
) where {D <: ContinuousPredictionGameDomain}
    return length(environment.tape1) - 1 < environment.max_length
end

function get_outcome_set(
    ::ContinuousPredictionGameDomain{Control},
    ::Float64
)
    outcome_set = [1.0, 1.0]
    return outcome_set
end

function get_outcome_set(
    ::ContinuousPredictionGameDomain{Competitive},
    distance_score::Float64
)
    outcome_set = [1 - distance_score, distance_score]
    return outcome_set
end

function get_outcome_set(
    ::ContinuousPredictionGameDomain{CooperativeMatching},
    distance_score::Float64
)
    outcome_set = [1 - distance_score, 1 - distance_score]
    return outcome_set
end

function get_outcome_set(
    ::ContinuousPredictionGameDomain{CooperativeMismatching},
    distance_score::Float64
)
    outcome_set = [distance_score, distance_score]
    return outcome_set
end

function get_outcome_set(
    environment::TapeEnvironment{D, <:Phenotype}
) where {D <: ContinuousPredictionGameDomain}
    distances = [
        min(diff1, diff2) for (diff1, diff2) in zip(environment.tape1, environment.tape2)
    ]
    max_dist = π * environment.max_length
    distance_score = sum(distances) / max_dist
    outcome_set = get_outcome_set(environment.domain, distance_score)
    return outcome_set
end

end