
function make_matches(
    matchmaker::MatchMaker,
    eco::Ecosystem,
    species_ids::Vector{String}
)
    if length(species_ids) != 2
        throw(ErrorException("Only two-entity interactions are supported for now."))
    end
    species1 = eco.species[species_ids[1]]
    species2 = eco.species[species_ids[2]]
    matches = make_matches(matchmaker, [species1, species2])
    return matches
end

function make_matches(interaction::Interaction, eco::Ecosystem)
    make_matches(interaction.matchmaker, eco, interaction.species_ids)
end