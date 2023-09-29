module Basic

export BasicMatch

using ..Abstract: Match

"""
    InteractionRecipe

Defines a template for an interaction. 

# Fields
- `domain_id::Int`: Identifier for the interaction domain.
- `indiv_ids::Vector{Int}`: Identifiers of individuals participating in the interaction.
"""
struct BasicMatch <: Match
    domain_id::String
    indiv_ids::Vector{Int}
end

end