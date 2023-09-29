module Abstract

export VectorGenotype, VectorGenotypeCreator, AbstractRNG

using ...Abstract: Genotype, GenotypeCreator

abstract type VectorGenotype <: Genotype end

abstract type VectorGenotypeCreator <: GenotypeCreator end

using Random: AbstractRNG

end