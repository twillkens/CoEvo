module Interfaces

export make_matches

using Random: AbstractRNG
using ..Matches.Abstract: Match
using ..Abstract: MatchMaker
using ....Species.Abstract: AbstractSpecies
using .....Ecosystems.Abstract: EcosystemCreator, Ecosystem

function make_matches(
    matchmaker::MatchMaker, 
    rng::AbstractRNG,
    all_species::Dict{String, AbstractSpecies},
    interaction_id::String,
    species_ids::Vector{String}
)
    throw(ErrorException(
        "`make_matches` not implemented for matchmaker $matchmaker"
        )
    )
end

end