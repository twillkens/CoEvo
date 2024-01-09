"""
    Genotypes

This module provides various representations for genotypes in an evolutionary algorithm. 
It contains several submodules for specific genotype structures such as vectors, genetic programs, 
neural networks, finite state machines, and function graphs. It also provides general abstract types 
and functions that are common for various genotypes.

## Submodules

- `Vectors`: 
  Genotype representation using vectors.
  
- `GeneticPrograms`: 
  Representation using genetic programming structures.

- `GnarlNetworks`: 
  Genotype structures inspired by neural networks.
  
- `FiniteStateMachines`: 
  Representation using finite state machines.

- `FunctionGraphs`: 
  Genotype structures using function graphs.

## Core Abstract Types

- `Gene`: 
  An abstract representation of a gene.

- `Genotype`: 
  An abstract representation of a genotype.

- `GenotypeCreator`: 
  An abstract type for objects that can create genotypes.

## Core Functions

- `create_genotypes(...)`: 
  Create a set of genotypes based on a given genotype creator, random number generator, gene ID counter, 
  and population size.

- `minimize(genotype::Genotype)`: 
  Provides a minimized version of the given genotype.

- `get_size(genotype::Genotype)`: 
  Returns the size of the given genotype.

## Note

The default implementations for `create_genotypes`, `minimize`, and `get_size` are placeholders 
that throw errors and need to be overridden for specific genotypes.

"""
module Genotypes

export Vectors, GeneticPrograms, GnarlNetworks, FiniteStateMachines, FunctionGraphs, SimpleFunctionGraphs

using Random: AbstractRNG
using HDF5: Group
using ..Counters: Counter

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

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

include("simple_function_graphs/simple_function_graphs.jl")
using .SimpleFunctionGraphs: SimpleFunctionGraphs

end