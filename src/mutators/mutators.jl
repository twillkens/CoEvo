module Mutators

export Identity, GeneticPrograms, GnarlNetworks, FiniteStateMachines, FunctionGraphs

using Random: AbstractRNG
using ..Counters: Counter
using ..Genotypes: Genotype
using ..Individuals: Individual

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("identity/identity.jl")
using .Identity: Identity

include("genetic_programs/genetic_programs.jl")
using .GeneticPrograms: GeneticPrograms

include("gnarl/gnarl.jl")
using .GnarlNetworks: GnarlNetworks

include("fsms/fsms.jl")
using .FiniteStateMachines: FiniteStateMachines

include("function_graphs/function_graphs.jl")
using .FunctionGraphs: FunctionGraphs

end