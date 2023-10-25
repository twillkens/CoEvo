export make_matches

function make_matches(
    matchmaker::MatchMaker, 
    random_number_generator::AbstractRNG,
    interaction_id::String,
    all_species::Vector{AbstractSpecies},
)
    throw(ErrorException(
        "`make_matches` not implemented for matchmaker $matchmaker and species $all_species."
        )
    )
end
