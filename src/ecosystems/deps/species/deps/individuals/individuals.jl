"""
    Individuals

A module dedicated to the definition and management of different types of individuals 
in a co-evolutionary system.
"""
module Individuals


export Genotypes, Phenotypes, Mutator, Abstract
export BasicIndividual, BasicIndividualCreator

include("abstract/abstract.jl")
using .Abstract

include("deps/genotypes/genotypes.jl")
using .Genotypes

include("deps/phenotypes/phenotypes.jl")
using .Phenotypes

include("deps/mutators/mutators.jl")
using .Mutators

include("types/basic.jl")

include("methods/methods.jl")


end
