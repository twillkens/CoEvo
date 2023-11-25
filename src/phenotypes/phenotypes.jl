module Phenotypes

export Defaults, Vectors, GeneticPrograms, GnarlNetworks, FiniteStateMachines, FunctionGraphs

using ..Genotypes: Genotype
using ..Individuals: Individual

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("defaults/defaults.jl")
using .Defaults: Defaults

include("vectors/vectors.jl")
using .Vectors: Vectors

include("genetic_programs/genetic_programs.jl")
using .GeneticPrograms: GeneticPrograms

include("gnarl_networks/gnarl_networks.jl")
using .GnarlNetworks: GnarlNetworks

include("finite_state_machines/finite_state_machines.jl")
using .FiniteStateMachines: FiniteStateMachines

include("function_graphs/function_graphs.jl")
using .FunctionGraphs: FunctionGraphs

end