module ContinuousPredictionGame

export get_outcome_set

using .....Environments.Concrete.Tape: TapeEnvironment
using ......Domains.Concrete: ContinuousPredictionGameDomain
using ......Domains.Interfaces: measure
using .......Species.Phenotypes.Abstract: Phenotype
using .......Species.Phenotypes.Interfaces: act!

import .....Environments.Interfaces: get_outcome_set, next!, is_active

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


function get_outcome_set(
    environment::TapeEnvironment{D, <:Phenotype}
) where {D <: ContinuousPredictionGameDomain}
    distances = [
        min(diff1, diff2) for (diff1, diff2) in zip(environment.tape1, environment.tape2)
    ]
    max_dist = π * environment.max_length
    distance_score = sum(distances) / max_dist
    outcome_set = measure(environment.domain, distance_score)
    return outcome_set
end

end