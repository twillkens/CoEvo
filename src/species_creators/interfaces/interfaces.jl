export create_species

function create_species(
    species_creator::SpeciesCreator,
    random_number_generator::AbstractRNG, 
    individual_id_counter::Counter,
    gene_id_counter::Counter
)::AbstractSpecies
    throw(ErrorException(
        "`create_species` not implemented for species $species_creator"
        )
    )
end

function create_species(
    species_creator::SpeciesCreator,
    random_number_generator::AbstractRNG,
    individual_id_counter::Counter,
    gene_id_counter::Counter,
    species::AbstractSpecies,
    evaluation::Evaluation
)::AbstractSpecies
    throw(ErrorException(
        "`create_species` not implemented for species $species_creator "
        )
    )
end
