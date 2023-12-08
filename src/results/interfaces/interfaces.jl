export get_individual_outcomes, get_observations

import ..Observers: get_observations

function get_individual_outcomes(result::Result)
    throw(ErrorException("`get_individual_outcomes` not implemented for $(typeof(result))"))
end

function get_observations(result::Result)
    throw(ErrorException("`get_observations` not implemented for $(typeof(result))"))
end

function get_individual_outcomes(results::Vector{Result})
    # Initialize a dictionary to store interaction outcomes between individuals
    individual_outcomes = Dict{Int, Dict{Int, Float64}}()

    for result in results
        outcome_dict = get_individual_outcomes(result)
        for (id, outcome) in outcome_dict
            # The opposing individual's ID is the one not matching the current ID
            opposing_id = setdiff(result.individual_ids, [id])[1]
            
            # If the key doesn't exist in `individual_outcomes`, initialize a new SortedDict 
            # and add the outcome
            get!(individual_outcomes, id, Dict{Int, Float64}())[opposing_id] = outcome
        end
    end

    return individual_outcomes
end

function get_observations(results::Vector{Result})
    observations = vcat([get_observations(result) for result in results]...)
    return observations
end