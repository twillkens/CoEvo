
"""
    make_interaction_recipes(domain_id::Int, cfg::DomainCfg, eco::Ecosystem) -> Vector{InteractionRecipe}

Construct interaction recipes for a given domain based on its configuration and an ecosystem.

# Arguments
- `domain_id::Int`: ID of the domain for which the recipes are being generated.
- `cfg::DomainCfg`: The configuration of the domain.
- `eco::Ecosystem`: The ecosystem from which entities are sourced for interactions.

# Returns
- A `Vector` of `InteractionRecipe` instances, detailing pairs of entities to interact.

# Throws
- Throws an `ArgumentError` if the number of entities in the domain configuration isn't 2.
"""
function make_matches(
    matchmaker::MatchMaker,
    eco::Ecosystem,
    species_ids::Vector{String}
)
    if length(topology.species_ids) != 2
        throw(ErrorException("Only two-entity interactions are supported for now."))
    end
    species1 = eco.species[species_ids[1]]
    species2 = eco.species[species_ids[2]]
    matches = make_matches(matchmaker, [species1, species2])
    return matches
end

function make_matches(topology::Topology, eco::Ecosystem)
    make_matches(topology.matchmaker, eco, topology.species_ids)
end