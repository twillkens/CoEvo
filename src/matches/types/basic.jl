module Basic

export BasicMatch

using ..Matches.Abstract: Match

import Base: ==, hash

"""
    InteractionRecipe

Defines a template for an interaction. 

# Fields
- `interaction_id::Int`: Identifier for the interaction interaction.
- `indiv_ids::Vector{Int}`: Identifiers of individuals participating in the interaction.
"""
struct BasicMatch <: Match
    interaction_id::String
    indiv_ids::Vector{Int}
end

function Base.:(==)(a::BasicMatch, b::BasicMatch)
    return a.interaction_id == b.interaction_id && a.indiv_ids == b.indiv_ids
end

function Base.hash(match::BasicMatch, h::UInt)
    return hash(hash(match.interaction_id, h), hash(match.indiv_ids, h))
end

end