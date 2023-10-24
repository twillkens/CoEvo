module FunctionGraphs

import ..Genotypes: create_genotypes, get_size, minimize

using Base: @kwdef
using Random: AbstractRNG
using ..Genotypes: Genotype, GenotypeCreator
using ...Counters: Counter

include("function_map.jl")

include("genotype.jl")

end