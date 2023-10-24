module FiniteStateMachines

import Base: ==, hash, length
import ..Genotypes.Interfaces: create_genotypes
import ..Genotypes.Interfaces: minimize

using Random: AbstractRNG, rand
using ...Counters: Counter, next!
using ..Genotypes.Abstract: Genotype, GenotypeCreator

include("genotype.jl")

include("minimize.jl")

end