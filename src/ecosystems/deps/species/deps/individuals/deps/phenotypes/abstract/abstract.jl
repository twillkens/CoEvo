module Abstract

export Phenotype, PhenotypeCreator, act

abstract type Phenotype end
abstract type PhenotypeCreator end


function act(pheno::Phenotype, ::Any)
    throw(ErrorException("act not implemented for $pheno"))
end

end