"""
    Replacers

This module provides various strategies to replace individuals in a population based on their evaluations. 
Replacers dictate how the next generation of individuals should be constituted, 
which is a fundamental aspect of evolutionary algorithms.
"""
module Replacers

export Abstract, Interfaces, Identity, Generational, Truncation

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("identity/identity.jl")
using .Identity: IdentityReplacer

include("generational/generational.jl")
using .Generational: GenerationalReplacer

include("truncation/truncation.jl")
using .Truncation: TruncationReplacer

end
