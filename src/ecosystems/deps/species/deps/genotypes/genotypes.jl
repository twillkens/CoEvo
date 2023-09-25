"""
    Substrates

Module providing substrate configurations and utilities, primarily for genotypes.
"""
module Genotypes

export VectorGenotype, VectorGenotypeConfiguration

include("abstract/abstract.jl")

using .Abstract

# Including vector-based genotype configurations
include("types/vectors/vectors.jl")

using .Vectors: VectorGenotype, VectorGenotypeConfiguration

end
