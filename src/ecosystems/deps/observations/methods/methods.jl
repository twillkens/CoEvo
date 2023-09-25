export get_outcomes

function get_outcomes(observations::Vector{<:Observation})
    # Initialize a dictionary to store interaction outcomes between individuals
    outcomes = Dict{Int, Dict{Int, Float64}}()

    for observation in observations 
        # Extract individual IDs and their respective outcomes from the interaction result
        indiv_id1, indiv_id2 = observation.indiv_ids
        outcome1, outcome2 = observation.outcome_set

        # Use `get!` to simplify dictionary insertion. 
        # If the key doesn't exist, a new dictionary is initialized and the outcome is recorded.
        get!(outcomes, indiv_id1, Dict{Int, Float64}())[indiv_id2] = outcome1
        get!(outcomes, indiv_id2, Dict{Int, Float64}())[indiv_id1] = outcome2
    end
    return outcomes
end