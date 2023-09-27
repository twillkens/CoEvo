
module Models

export Defaults
export Vectors
export GeneticPrograms

include("defaults/defaults.jl")
include("vectors/vectors.jl")
include("genetic_programs/genetic_programs.jl")

using .Defaults: Defaults 
using .Vectors: Vectors
using .GeneticPrograms: GeneticPrograms

end