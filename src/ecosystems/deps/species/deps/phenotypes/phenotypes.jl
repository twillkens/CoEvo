module Phenotypes

export Abstract, Vectors, Defaults, GnarlNetworks, FiniteStateMachines, FunctionGraphs
# export GeneticPrograms

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("types/defaults/defaults.jl")
using .Defaults: Defaults

include("types/vectors/vectors.jl")
using .Vectors: Vectors

#include("types/genetic_programs/genetic_programs.jl")
#using .GeneticPrograms: GeneticPrograms

include("types/gnarl/gnarl.jl")
using .GnarlNetworks: GnarlNetworks

include("types/fsms/fsms.jl")
using .FiniteStateMachines: FiniteStateMachines

include("types/function_graphs/function_graphs.jl")
using .FunctionGraphs: FunctionGraphs

end