module Results

export Result, get_individual_outcomes, get_observations

using DataStructures: SortedDict
using ...Ecosystems.Interactions.Observers.Abstract: Observation

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

function get_individual_outcomes(results::Vector{<:Result})
    # Initialize a dictionary to store interaction outcomes between individuals
    individual_outcomes = Dict{Int, SortedDict{Int, Float64}}()

    for result in results
        # Extract individual IDs and their respective outcomes from the interaction result
        id_1, id_2 = result.indiv_ids
        outcome_1, outcome_2 = result.outcome_set

        # If the key doesn't exist in `individual_outcomes`, initialize a new SortedDict and add the outcome
        get!(individual_outcomes, id_1, SortedDict{Int, Float64}())[id_2] = outcome_1
        get!(individual_outcomes, id_2, SortedDict{Int, Float64}())[id_1] = outcome_2
    end

    return individual_outcomes
end


function get_observations(results::Vector{<:Result})
    return [observation for result in results for observation in result.observations]
end


end