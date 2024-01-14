module Basic

export BasicResult

import ....Interfaces: get_individual_outcomes, get_observations

using DataStructures: SortedDict
using ....Abstract

struct BasicResult{O <: Observation} <: Result
    interaction_id::String
    individual_ids::Vector{Int}
    outcome_set::Vector{Float64}
    observations::Vector{O}
end

function get_individual_outcomes(result::BasicResult)
    if length(result.individual_ids) != 2
        throw(ErrorException("BasicResult must have exactly two individual IDs"))
    end
    id_1, id_2 = result.individual_ids
    outcome_1, outcome_2 = result.outcome_set
    outcome_pairs = [id_1 => outcome_1, id_2 => outcome_2]
    outcome_dict = Dict(outcome_pairs)
    return outcome_dict
end

function get_observations(result::BasicResult)
    observations = [observation for observation in result.observations]
    return observations
end

end