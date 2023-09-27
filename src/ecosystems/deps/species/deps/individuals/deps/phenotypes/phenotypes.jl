module Phenotypes

export Abstract, Vectors
export BasicVectorPhenotype, VectorPhenotype
export BasicGeneticProgramPhenotype, BasicGeneticProgramPhenotypeCreator

include("abstract/abstract.jl")

using .Abstract

include("types/types.jl")

using .Abstract: Abstract
using .Vectors: VectorPhenotype, BasicVectorPhenotype
using .GeneticPrograms: GeneticPrograms, BasicGeneticProgramPhenotype

end