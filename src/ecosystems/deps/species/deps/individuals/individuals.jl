"""
    Individuals

A module dedicated to the definition and management of different types of individuals 
in a co-evolutionary system.
"""
module Individuals

export Genotypes, Phenotypes, Mutator, Abstract, Interfaces

include("abstract/abstract.jl")
using .Abstract: Abstract

include("deps/genotypes/genotypes.jl")
using .Genotypes: Genotypes

include("deps/phenotypes/phenotypes.jl")
using .Phenotypes: Phenotypes

include("deps/mutators/mutators.jl")
using .Mutators: Mutators

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("types/basic.jl")

include("methods/methods.jl")

end
