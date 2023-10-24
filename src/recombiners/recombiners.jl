"""
    Recombiners

This module provides recombination strategies for individuals during the evolution process.
Currently, it implements the `CloneRecombiner`, which creates new individuals by cloning the parents.

# Usage
Use `CloneRecombiner` to create offspring by directly copying the genotype of parents.
"""
module Recombiners

export Clone, Identity

using Random: AbstractRNG
using ..Counters: Counter
using ..Individuals: Individual

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("clone/clone.jl")
using .Clone: Clone

include("identity/identity.jl")
using .Identity: Identity

end
