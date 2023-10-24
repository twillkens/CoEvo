module Interfaces

export create_genotypes, minimize, get_size

using Random: AbstractRNG

using ...Counters: Counter
using ..Genotypes.Abstract: Genotype, GenotypeCreator

function create_genotypes(
    genotype_creator::GenotypeCreator, 
    random_number_generator::AbstractRNG,
    gene_id_counter::Counter,
    n_population::Int
)::Vector{Genotype}
    throw(ErrorException(
        "Default genotype creation for $genotype_creator, not implemented."
    ))
end

function minimize(genotype::Genotype)::Genotype
    throw(ErrorException(
        "Default genotype minimization for $genotype, not implemented."
    ))
end

function get_size(genotype::Genotype)::Int
    throw(ErrorException(
        "Default genotype size for $genotype, not implemented."
    ))
end

end