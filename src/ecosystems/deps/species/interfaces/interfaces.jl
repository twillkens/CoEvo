module Interfaces

export create_species

using ..Species.Abstract: SpeciesCreator, AbstractRNG, AbstractSpecies
using ....Ecosystems.Utilities.Counters: Counter
using ....Ecosystems.Species.Evaluators.Abstract: Evaluation
using ....Ecosystems.Species.Individuals: Individual


function create_species(
    species_creator::SpeciesCreator,
    rng::AbstractRNG, 
    indiv_id_counter::Counter,
    gene_id_counter::Counter
)::AbstractSpecies
    throw(ErrorException(
        "`create_species` not implemented for species $species_creator"
        )
    )
end

function create_species(
    species_creator::SpeciesCreator,
    rng::AbstractRNG,
    indiv_id_counter::Counter,
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