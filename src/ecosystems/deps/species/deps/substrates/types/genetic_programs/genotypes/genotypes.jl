module Genotypes

export BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeConfiguration
export add_function, remove_function, swap_node, splice_function

include("types/basic.jl")
include("utilities/utilities.jl")
include("methods/methods.jl")

end