module Interfaces

export create_species, get_all_individuals

using DataStructures: OrderedDict
using ..Abstract: SpeciesCreator, AbstractRNG
using ....Ecosystems.Utilities.Counters: Counter
using ....Ecosystems.Species.Evaluators.Abstract: Evaluation
using ....Ecosystems.Species.Individuals.Abstract: Individual

function create_species(
    species_creator::SpeciesCreator,
    rng::AbstractRNG,
    indiv_id_counter::Counter,
    gene_id_counter::Counter,
    pop_evals::OrderedDict{Individual, Evaluation},
    children_evals::OrderedDict{Individual, Evaluation}
)
    throw(ErrorException(
        "`create_species` not implemented for species $species_creator, rng $rng, indiv_id_counter $indiv_id_counter, gene_id_counter $gene_id_counter, pop_evals $pop_evals, children_evals $children_evals"
        )
    )
end

function get_all_individuals(
    species::AbstractSpecies
)
    throw(ErrorException(
        "`get_all_individuals` not implemented for species $species"
        )
    )
end


end