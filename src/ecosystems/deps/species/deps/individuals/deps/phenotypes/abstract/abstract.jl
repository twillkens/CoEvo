module Abstract

export Phenotype, PhenotypeCreator, Genotype

using ...Genotypes.Abstract: Genotype

abstract type Phenotype end

abstract type PhenotypeCreator end


end