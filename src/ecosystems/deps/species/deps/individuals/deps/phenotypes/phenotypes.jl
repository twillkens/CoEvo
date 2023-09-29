module Phenotypes

export Abstract, Vectors, Defaults, GeneticPrograms

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("types/defaults/defaults.jl")
using .Defaults: Defaults

include("types/vectors/vectors.jl")
using .Vectors: Vectors

include("types/genetic_programs/genetic_programs.jl")
using .GeneticPrograms: GeneticPrograms

end