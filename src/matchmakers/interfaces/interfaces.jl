module Interfaces

export make_matches

using Random: AbstractRNG
using ...Matches: Match
using ...Species: AbstractSpecies
using ..MatchMakers: MatchMaker

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

end