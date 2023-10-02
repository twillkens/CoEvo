module Abstract

export VectorPhenotype, VectorPhenotypeCreator

using ....Species.Phenotypes.Abstract: Phenotype

abstract type VectorPhenotype <: Phenotype end 

abstract type VectorPhenotypeCreator <: Phenotype end 

end