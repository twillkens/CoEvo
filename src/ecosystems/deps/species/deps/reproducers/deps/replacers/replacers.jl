"""
    Replacers

This module provides various strategies to replace individuals in a population based on their evaluations. 
Replacers dictate how the next generation of individuals should be constituted, 
which is a fundamental aspect of evolutionary algorithms.
"""
module Replacers

export Abstract, Interfaces, Types

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("types/types.jl")
using .Types: Types

end
