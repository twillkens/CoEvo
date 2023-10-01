module Abstract

export VectorGenotype, VectorGenotypeCreator

using ...Genotypes.Abstract: Genotype, GenotypeCreator

abstract type VectorGenotype <: Genotype end

abstract type VectorGenotypeCreator <: GenotypeCreator end

end