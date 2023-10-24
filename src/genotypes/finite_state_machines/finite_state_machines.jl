module FiniteStateMachines

import Base: ==, hash, length
import ..Genotypes: create_genotypes, minimize

using Random: AbstractRNG, rand
using ...Counters: Counter, count!
using ..Genotypes: Genotype, GenotypeCreator

include("genotype.jl")

include("minimize.jl")

end