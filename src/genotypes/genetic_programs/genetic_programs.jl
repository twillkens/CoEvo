"""
    module GeneticPrograms

Provides structures and utilities for genotype representations of genetic programs.
"""
module GeneticPrograms

import ..Genotypes: create_genotypes   

using Random: AbstractRNG
using ...Counters: Counter, count!
using ..Genotypes: Genotype, GenotypeCreator

include("utilities.jl")

include("genotype.jl")

include("traverse.jl")

end