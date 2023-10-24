module Basic

export BasicMatch

using ..Matches.Abstract: Match

import Base: ==, hash

struct BasicMatch <: Match
    interaction_id::String
    individual_ids::Vector{Int}
end

function Base.:(==)(a::BasicMatch, b::BasicMatch)
    return a.interaction_id == b.interaction_id && a.individual_ids == b.individual_ids
end

function Base.hash(match::BasicMatch, h::UInt)
    return hash(hash(match.interaction_id, h), hash(match.individual_ids, h))
end

end