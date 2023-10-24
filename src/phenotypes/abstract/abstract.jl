module Abstract

export Phenotype, PhenotypeCreator

using ...Genotypes.Abstract: Genotype

abstract type Phenotype end

abstract type PhenotypeCreator end

end