module Mutators

export Abstract, Interfaces, Identity, GnarlNetworks, FiniteStateMachines, FunctionGraphs

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("identity/identity.jl")
using .Identity: Identity

#include("genetic_programs/genetic_programs.jl")
#using .GeneticPrograms: GeneticPrograms, GeneticProgramMutator

include("gnarl/gnarl.jl")
using .GnarlNetworks: GnarlNetworks

include("fsms/fsms.jl")
using .FiniteStateMachines: FiniteStateMachines

include("function_graphs/function_graphs.jl")
using .FunctionGraphs: FunctionGraphs

end