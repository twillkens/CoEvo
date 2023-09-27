"""
    VectorSubstrate

Module offering vector-based genotype configurations along with related utilities.
This module facilitates the definition and management of genotypes that are represented 
as vectors of real numbers.
"""
module Vectors

export BasicVectorGenotype, BasicVectorGenotypeCreator

include("abstract/abstract.jl")

using .Abstract

include("types/basic.jl")

end
