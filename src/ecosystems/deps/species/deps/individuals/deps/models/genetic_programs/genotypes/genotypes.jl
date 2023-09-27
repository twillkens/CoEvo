module Genotypes

export BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeCreator
export Mutations
export add_function, remove_function, swap_node, splice_function

include("types/basic.jl")
include("utilities/utilities.jl")
include("methods/methods.jl")

using .Mutations: Mutations, add_function, remove_function, swap_node, splice_function

end