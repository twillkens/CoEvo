module Interfaces

export create_genotypes

using ..Abstract: Genotype, GenotypeCreator, AbstractRNG
using .....Ecosystems.Utilities.Counters: Counter

function create_genotypes(
    geno_creator::GenotypeCreator, 
    rng::AbstractRNG,
    gene_id_counter::Counter,
    n_pop::Int
)::Genotype
    throw(ErrorException(
        "Default genotype creation for $geno_creator, not implemented."
    ))
end

end