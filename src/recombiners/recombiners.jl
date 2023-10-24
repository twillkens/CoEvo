"""
    Recombiners

This module provides recombination strategies for individuals during the evolution process.
Currently, it implements the `CloneRecombiner`, which creates new individuals by cloning the parents.

# Usage
Use `CloneRecombiner` to create offspring by directly copying the genotype of parents.
"""
module Recombiners

export Abstract, Interfaces, Clone, Identity

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("clone/clone.jl")
using .Clone: Clone

include("identity/identity.jl")
using .Identity: Identity

end
