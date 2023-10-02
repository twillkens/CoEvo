module Methods

using ..Abstract: MatchMaker
using ....Species.Abstract: AbstractSpecies
using ....Ecosystems.Abstract: EcosystemCreator, Ecosystem
using ....Interactions.Abstract: Interaction
import ..MatchMakers.Interfaces: make_matches



function make_matches(
    matchmaker::MatchMaker,
    interaction::Interaction, 
    eco_creator::EcosystemCreator, 
    eco::Ecosystem
)
    make_matches(
        matchmaker, 
        eco_creator.rng, 
        eco.species, 
        interaction.id, 
        interaction.species_ids
    )
end

end