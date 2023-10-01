module Genotypes

export Abstract, Vectors, GeneticPrograms

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("types/vectors/vectors.jl")
using .Vectors: Vectors

include("types/genetic_programs/genetic_programs.jl")
using .GeneticPrograms: GeneticPrograms

include("methods/methods.jl")


end