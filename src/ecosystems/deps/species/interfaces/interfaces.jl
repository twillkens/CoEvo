module Interfaces

export create_species

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


end