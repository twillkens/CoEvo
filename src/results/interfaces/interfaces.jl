export get_individual_outcomes, get_observations

function get_individual_outcomes(result::Result)
    throw(ErrorException("`get_individual_outcomes` not implemented for $(typeof(result))"))
end

function get_observations(result::Result)
    throw(ErrorException("`get_observations` not implemented for $(typeof(result))"))
end

function get_individual_outcomes(results::Vector{Result})
    outcome_dicts = [get_individual_outcomes(result) for result in results]
    # Initialize a dictionary of dictionaries to store the individual outcomes
    # Pre-allocate the dictionary to avoid resizing
    # The inner dictionary is indexed by the opposing individual's ID
    # The outer dictionary is indexed by the individual's ID
    ids = Set(id for od in outcome_dicts for id in keys(od))
    individual_outcomes = Dict{Int, Dict{Int, Float64}}(
                            id=>Dict{Int, Float64}()
                            for id in ids)

    for (i, result) in enumerate(results)
        for (id, outcome) in outcome_dicts[i]
            # The opposing individual's ID is the one not matching the current ID
            @inbounds opposing_id = result.individual_ids[1] == id ? result.individual_ids[2] : result.individual_ids[1]
            @inbounds individual_outcomes[id][opposing_id] = outcome
        end
    end
    # convert individual outcomes to sorteddict
    sorted_individual_outcomes = Dict{Int, SortedDict{Int, Float64}}(
        id => SortedDict(outcome_dict) 
        for (id, outcome_dict) in individual_outcomes)

    return sorted_individual_outcomes
end

function get_observations(results::Vector{Result})
    observations = vcat([get_observations(result) for result in results]...)
    return observations
end
