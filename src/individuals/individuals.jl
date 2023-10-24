"""
    Individuals

A module dedicated to the definition and management of different types of individuals 
in a co-evolutionary system.
"""
module Individuals

export Abstract, Interfaces, Basic

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("basic/basic.jl")
using .Basic: Basic

end
