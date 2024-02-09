export create_species, update_species!, create_from_dict

using ..Abstract

function create_species(species_creator::SpeciesCreator, reproducer::Reproducer, state::State)
    species_creator = typeof(species_creator)
    reproducer = typeof(reproducer)
    state = typeof(state)
    error("`create_species` not implemented for $species_creator, $reproducer, $state")
end

function update_species!(
    species::AbstractSpecies, 
    species_creator::SpeciesCreator, 
    evaluation::Evaluation,
    reproducer::Reproducer,
    state::State
)
    species = typeof(species)
    species_creator = typeof(species_creator)
    evaluation = typeof(evaluation)
    reproducer = typeof(reproducer)
    state = typeof(state)
    error(
        "`update_species!` not implemented for $species, $species_creator, $evaluation, " * 
        "$reproducer, $state"
    )
end

function create_from_dict(species_creator::SpeciesCreator, dict::Dict, state::State)
    species_creator = typeof(species_creator)
    dict = typeof(dict)
    state = typeof(state)
    error("`create_from_dict` not implemented for $species_creator, $dict, $state")
end