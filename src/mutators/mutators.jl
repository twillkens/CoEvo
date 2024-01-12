module Mutators

export Identity, Vectors, GeneticPrograms, GnarlNetworks, FiniteStateMachines, FunctionGraphs
export SimpleFunctionGraphs

using Random: AbstractRNG
using ..Counters: Counter
using ..Genotypes: Genotype
using ..Individuals: Individual
using ..Individuals.Basic: BasicIndividual

include("interfaces/interfaces.jl")

include("identity/identity.jl")
using .Identity: Identity

include("vectors/vectors.jl")
using .Vectors: Vectors

include("genetic_programs/genetic_programs.jl")
using .GeneticPrograms: GeneticPrograms

include("gnarl/gnarl.jl")
using .GnarlNetworks: GnarlNetworks

include("finite_state_machines/finite_state_machines.jl")
using .FiniteStateMachines: FiniteStateMachines

include("function_graphs/function_graphs.jl")
using .FunctionGraphs: FunctionGraphs

#include("simple_function_graphs/simple_function_graphs.jl")
#using .SimpleFunctionGraphs: SimpleFunctionGraphs

include("binomial_function_graphs/binomial_function_graphs.jl")
using .BinomialFunctionGraphs: BinomialFunctionGraphs
end