module Genotypes

export Abstract, Interfaces, Vectors, GnarlNetworks, FiniteStateMachines, FunctionGraphs

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("vectors/vectors.jl")
using .Vectors: Vectors

#include("types/genetic_programs/genetic_programs.jl")
#using .GeneticPrograms: GeneticPrograms

include("gnarl/gnarl.jl")
using .GnarlNetworks: GnarlNetworks

include("fsms/fsms.jl")
using .FiniteStateMachines: FiniteStateMachines

include("function_graphs/function_graphs.jl")
using .FunctionGraphs: FunctionGraphs

end