module Interfaces

export create_genotypes, minimize

using Random: AbstractRNG

using ..Genotypes.Abstract: Genotype, GenotypeCreator, AbstractRNG
using .....Ecosystems.Utilities.Counters: Counter

function create_genotypes(
    geno_creator::GenotypeCreator, 
    rng::AbstractRNG,
    gene_id_counter::Counter,
    n_pop::Int
)::Vector{Genotype}
    throw(ErrorException(
        "Default genotype creation for $geno_creator, not implemented."
    ))
end

function minimize(geno::Genotype)::Genotype
    throw(ErrorException(
        "Default genotype minimization for $geno, not implemented."
    ))
end

end