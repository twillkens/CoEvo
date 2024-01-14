export create_species

using ..Abstract

function create_species(species_creator::SpeciesCreator, state::State)::AbstractSpecies
    species_creator = typeof(species_creator)
    state = typeof(state)
    throw(ErrorException(
        "`create_species` not implemented for species creator $species_creator with state $state"
        )
    )
end

function create_species(
    species_creator::SpeciesCreator, species::AbstractSpecies, state::State
)::AbstractSpecies
    species_creator = typeof(species_creator)
    state = typeof(state)
    throw(ErrorException(
        "`create_species` not implemented for species $species_creator with state $state"
        )
    )
end

function create_species(
    species_creators::Vector{<:SpeciesCreator},
    all_species::Vector{<:AbstractSpecies},
    state::State
)
    species = [
        create_species(species_creator, species, state)
        for (species_creator, species) in zip(species_creators, all_species)
    ]
    return species
end
