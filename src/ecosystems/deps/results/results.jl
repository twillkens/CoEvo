module Results

export Result, get_indiv_outcomes, get_observations

using ..Ecosystems.Interactions.Observers: Observation

struct Result{O <: Observation}
    interaction_id::String
    indiv_ids::Vector{Int}
    outcome_set::Vector{Float64}
    observations::Vector{O}
end

"""
    get_outcomes(observations::Vector{<:Observation})

Extracts and organizes interaction outcomes between pairs of individuals from a given set of 
observations.

# Arguments
- `observations::Vector{<:Observation}`: A vector of observations, where each observation typically captures the outcomes of interactions for specific pairs of individuals.

# Returns
- A dictionary where the primary keys are individual IDs. The value associated with each individual ID is another dictionary. In this inner dictionary, the keys are IDs of interacting partners, and the values are the outcomes of the interactions.
"""
function get_indiv_outcomes(results::Vector{<:Result})
    # Initialize a dictionary to store interaction outcomes between individuals
    indiv_outcomes = Dict{Int, Dict{Int, Float64}}()

    for result in results 
        # Extract individual IDs and their respective outcomes from the interaction result
        indiv_id1, indiv_id2 = result.indiv_ids
        outcome1, outcome2 = result.outcome_set

        # Use `get!` to simplify dictionary insertion. 
        # If the key doesn't exist, a new dictionary is initialized and the outcome is recorded.
        get!(indiv_outcomes, indiv_id1, Dict{Int, Float64}())[indiv_id2] = outcome1
        get!(indiv_outcomes, indiv_id2, Dict{Int, Float64}())[indiv_id1] = outcome2
    end
    return indiv_outcomes
end

function get_observations(results::Vector{<:Result})
    return [observation for result in results for observation in result.observations]
end


end