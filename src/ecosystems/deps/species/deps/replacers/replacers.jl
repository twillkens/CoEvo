"""
    Replacers

This module provides various strategies to replace individuals in a population based on their evaluations. 
Replacers dictate how the next generation of individuals should be constituted, 
which is a fundamental aspect of evolutionary algorithms.
"""
module Replacers

export IdentityReplacer, GenerationalReplacer

include("types/identity.jl")
include("types/generational.jl")

end
