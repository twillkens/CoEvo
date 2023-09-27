module Mutators

export GeneticPrograms

include("abstract/abstract.jl")

include("types/types.jl")
using .GeneticPrograms

include("methods/methods.jl")

end