module FunctionGraphs

import ..Genotypes.Interfaces: create_genotypes, get_size, minimize

using Base: @kwdef
using Random: AbstractRNG
using ..Genotypes.Abstract: Genotype, GenotypeCreator
using ...Counters.Abstract: Counter
using ...Counters.Interfaces: count!

include("function_map.jl")

include("genotype.jl")

end