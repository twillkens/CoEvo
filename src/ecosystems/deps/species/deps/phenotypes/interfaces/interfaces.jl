module Interfaces

export create_phenotype, act!

using ..Abstract: Phenotype, PhenotypeCreator, Genotype

function create_phenotype(phenotype_creator::PhenotypeCreator, geno::Genotype)::Phenotype
    throw(ErrorException(
        "Default phenotype creation for $phenotype_creator and $geno not implemented."
    ))
end

function act!(phenotype::Phenotype, args...)
    throw(ErrorException("act! not implemented for $phenotype"))
end

function act!(phenotype::Phenotype)
    return act!(phenotype, nothing)
end

function reset!(phenotype::Phenotype)
    throw(ErrorException("reset! not implemented for $phenotype"))
end

end