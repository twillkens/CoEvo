module GeneticPrograms

export ExpressionNodeGene, GeneticProgramGenotype, GeneticProgramGenotypeCreator
export Utilities, Methods

include("genes.jl")
using .Genes: ExpressionNodeGene

include("genotypes.jl")
using .Genotypes: GeneticProgramGenotype

include("creators.jl")
using .Creators: GeneticProgramGenotypeCreator

include("utilities.jl")
using .Utilities: Utilities

include("methods/methods.jl")
using .Methods: Methods

end