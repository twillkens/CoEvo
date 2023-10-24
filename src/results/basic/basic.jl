module Basic

export BasicResult

import ..Results: get_individual_outcomes, get_observations

using DataStructures: SortedDict
using ...Observers: Observation
using ..Results: Result

struct BasicResult{O <: Observation}
    interaction_id::String
    individual_ids::Vector{Int}
    outcome_set::Vector{Float64}
    observations::Vector{O}
end

function get_individual_outcomes(results::Vector{<:BasicResult})
    # Initialize a dictionary to store interaction outcomes between individuals
    individual_outcomes = Dict{Int, SortedDict{Int, Float64}}()

    for result in results
        # Extract individual IDs and their respective outcomes from the interaction result
        id_1, id_2 = result.individual_ids
        outcome_1, outcome_2 = result.outcome_set

        # If the key doesn't exist in `individual_outcomes`, initialize a new SortedDict and add the outcome
        get!(individual_outcomes, id_1, SortedDict{Int, Float64}())[id_2] = outcome_1
        get!(individual_outcomes, id_2, SortedDict{Int, Float64}())[id_1] = outcome_2
    end

    return individual_outcomes
end

function get_observations(results::Vector{<:BasicResult})
    observations = [observation for result in results for observation in result.observations]
    return observations
end

end