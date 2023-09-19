module Reproduction

using Random
using StableRNGs
using JLD2
using ..Common
using ..Indivs
using ..Indivs.GP: pruned_size    
include("nsga.jl")
include("replacers.jl")
include("selectors.jl")
include("recombiners.jl")
include("mutators.jl")
include("mutators/fsm.jl")
include("mutators/gnarl.jl")
include("spawner.jl")

end