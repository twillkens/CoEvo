module Abstract

export GeneticProgramGenotype, ExpressionNodeGene, GeneticProgramGenotypeCreator

using ...Genotypes.Abstract: Genotype, GenotypeCreator

abstract type ExpressionNodeGene end

abstract type GeneticProgramGenotype <: Genotype end

abstract type GeneticProgramGenotypeCreator <: GenotypeCreator end

end