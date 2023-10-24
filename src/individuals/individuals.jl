"""
    Individuals

A module dedicated to the definition and management of different types of individuals 
in a co-evolutionary system.
"""
module Individuals

export Basic

using Random: AbstractRNG
using ..Counters: Counter
using ..Genotypes: GenotypeCreator

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

end
