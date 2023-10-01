module Interfaces

export create_genotype

using ..Abstract: Genotype, GenotypeCreator, AbstractRNG
using ......Ecosystems.Utilities.Counters: Counter

function create_genotype(
    geno_creator::GenotypeCreator, 
    ::AbstractRNG,
    ::Counter
)::Genotype
    throw(ErrorException(
        "Default genotype creation for $geno_creator, not implemented."
    ))
end

end