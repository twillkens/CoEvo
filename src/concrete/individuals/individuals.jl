"""
    Individuals

A module dedicated to the definition and management of different types of individuals 
in a co-evolutionary system.
"""
module Individuals

export Basic, Modes

include("basic/basic.jl")
using .Basic: Basic

include("modes/modes.jl")
using .Modes: Modes

include("dodo/dodo.jl")
using .Dodo: Dodo

end
