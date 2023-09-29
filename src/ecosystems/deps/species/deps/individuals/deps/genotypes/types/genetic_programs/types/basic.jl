module Basic

export BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeCreator
export Traverse, Manipulate

include("gene.jl")
include("genotype.jl")
include("creator.jl")

include("methods/traverse.jl")
using .Traverse: Traverse

include("methods/manipulate.jl")
using .Manipulate: Manipulate


end