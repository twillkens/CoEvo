module Interfaces

export create_species, get_all_individuals

using ..Abstract: SpeciesCreator, AbstractRNG
using ....Ecosystems.Utilities.Counters: Counter
using ....Ecosystems.Species.Evaluators.Abstract: Evaluation
using ....Ecosystems.Species.Individuals.Abstract: Individual


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

function get_all_individuals(
    species::AbstractSpecies
)::Dict{Int, Individual}
    throw(ErrorException(
        "`get_all_individuals` not implemented for species $species"
        )
    )
end


end