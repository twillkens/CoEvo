module GeneticPrograms

export BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeCreator
export get_child_index, all_nodes, get_nodes, get_node, get_root, get_parent_node
export get_child_nodes, get_ancestors, get_descendents, replace_child!, pruned_size
export add_function, remove_function, splice_function, swap_node, inject_noise
export Utilities

using ...Individuals.Abstract: Genotype, GenotypeCreator

abstract type GeneticProgramGenotype <: Genotype end
abstract type GeneticProgramGenotypeCreator <: GenotypeCreator end

include("utilities/utilities.jl")
using .Utilities: Utilities
include("types/basic.jl")
include("methods/methods.jl")

end