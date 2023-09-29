module Interfaces

using ..Matches.Abstract: Match
using ..Abstract: AbstractSpecies

function make_matches(
    matchmaker::MatchMaker, species::Vector{<:AbstractSpecies}::Vector{Match}
)
    throw(ErrorException(
        "`make_matches` not implemented for matchmaker $matchmaker, species $species"
        )
    )
end

end