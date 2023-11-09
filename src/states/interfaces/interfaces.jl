export create_species

function create_species(state::State, species_creators::Vector{SpeciesCreator})
    throw(ErrorException(
        "`construct_new_species` not implemented for $state and $species_creators.")
    )
end