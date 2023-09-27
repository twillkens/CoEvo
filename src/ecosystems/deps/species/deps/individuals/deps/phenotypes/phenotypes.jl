module Phenotypes

export BasicVectorGenotype, BasicVectorGenotypeCreator
export BasicGeneticProgramPhenotype, BasicGeneticProgramPhenotypeCreator

include("abstract/abstract.jl")

include("types/types.jl")
using .Vectors: BasicVectorPhenotype

using .GeneticPrograms: BasicGeneticProgramPhenotype

end