module Basic

export BasicResult, SimpleOutcome

import ....Interfaces: get_individual_outcomes

using DataStructures: SortedDict
using ....Abstract

struct BasicResult{M <: Match, O <: Observation} <: Result
    match::M
    outcome_set::Vector{Float64}
    observation::O
end

struct SimpleOutcome{T, U, R <: Real} <: Result
    species_id::String
    id::T
    other_id::U
    outcome::R
end

function get_individual_outcomes(result::BasicResult)
    if length(result.match.individual_ids) != 2
        throw(ErrorException("BasicResult must have exactly two individual IDs"))
    end
    species_id_1, species_id_2 = result.match.species_ids
    id_1, id_2 = result.match.individual_ids
    outcome_value_1, outcome_value_2 = result.outcome_set
    outcomes = [
        SimpleOutcome(species_id_1, id_1, id_2, outcome_value_1),
        SimpleOutcome(species_id_2, id_2, id_1, outcome_value_2),
    ]
    return outcomes
end



end