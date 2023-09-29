module Abstract

export GeneticProgramGenotype, GeneticProgramGenotypeCreator, AbstractRNG

using Random: AbstractRNG
using ....Genotypes.Abstract: Genotype, GenotypeCreator

abstract type GeneticProgramGenotype <: Genotype end

abstract type GeneticProgramGenotypeCreator <: GenotypeCreator end

end