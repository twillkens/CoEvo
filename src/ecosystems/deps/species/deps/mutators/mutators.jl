module Mutators

export Abstract, Interfaces, GeneticPrograms, Identity, Methods

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("types/identity/identity.jl")
using .Identity: Identity

include("types/genetic_programs/genetic_programs.jl")
using .GeneticPrograms: GeneticPrograms

include("methods/methods.jl")
using .Methods: Methods

end