module Basic

export BasicMatch

using ..Abstract: Match

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

end