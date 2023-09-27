module Abstract

using .....Individuals.Abstract: Genotype, Phenotype, GenotypeCreator, PhenotypeCreator

abstract type VectorGenotype <: Genotype end

abstract type VectorGenotypeCreator <: GenotypeCreator end

abstract type VectorPhenotype <: Phenotype end

abstract type VectorPhenotypeCreator <: PhenotypeCreator end

end