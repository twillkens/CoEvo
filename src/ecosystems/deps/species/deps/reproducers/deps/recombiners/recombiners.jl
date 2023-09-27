"""
    Recombiners

This module provides recombination strategies for individuals during the evolution process.
Currently, it implements the `CloneRecombiner`, which creates new individuals by cloning the parents.

# Usage
Use `CloneRecombiner` to create offspring by directly copying the genotype of parents.
"""
module Recombiners

export CloneRecombiner

include("abstract/abstract.jl")
using .Abstract

include("types/clone.jl")

end
