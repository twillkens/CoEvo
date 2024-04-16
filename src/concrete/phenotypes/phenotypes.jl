module Phenotypes

export Defaults, Vectors

include("defaults/defaults.jl")
using .Defaults: Defaults

include("vectors/vectors.jl")
using .Vectors: Vectors

end