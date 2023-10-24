module Interfaces

export create_species

using Random: AbstractRNG
using ...Species.Abstract: AbstractSpecies
using ...Counters: Counter
using ...Evaluators.Abstract: Evaluation
using ...Individuals.Abstract: Individual
using ..SpeciesCreators.Abstract: SpeciesCreator

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

end