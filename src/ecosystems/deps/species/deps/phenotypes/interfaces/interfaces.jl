module Interfaces

export create_phenotype, act

using ..Abstract: Phenotype, PhenotypeCreator, Genotype

function create_phenotype(pheno_creator::PhenotypeCreator, geno::Genotype)::Phenotype
    throw(ErrorException(
        "Default phenotype creation for $pheno_creator and $geno not implemented."
    ))
end

function act(pheno::Phenotype, ::Any)
    throw(ErrorException("act not implemented for $pheno"))
end

function act(pheno::Phenotype)
    return act(pheno, nothing)
end


end