"""
Provides structures and utilities to represent and manipulate Finite State Machines (FSMs) as 
genotypes within the context of coevolutionary algorithms.
"""
module FiniteStateMachines

import Base: ==, hash, length
import ..Genotypes: create_genotypes, minimize

using Random: AbstractRNG, rand
using ...Counters: Counter, count!
using ..Genotypes: Genotype, GenotypeCreator

include("genotype.jl")

include("minimize.jl")

end