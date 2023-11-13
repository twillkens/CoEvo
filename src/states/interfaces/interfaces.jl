export create_species

function create_species(species_creators::Vector{SpeciesCreator}, state::State)
    throw(ErrorException(
        "`construct_new_species` not implemented for $state and $species_creators.")
    )
end