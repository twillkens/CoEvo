module Indivs
using JLD2
using Random
using ..Common

include("vector.jl")
include("fsm.jl")
include("hopcroft.jl")
include("gnarl/gnarl.jl")
include("gp/gp.jl")
end