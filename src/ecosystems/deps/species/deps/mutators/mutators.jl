module Mutators

export Abstract, Interfaces, GeneticProgram, Identity, Methods

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("types/identity/identity.jl")
using .Identity: Identity

include("types/genetic_program/genetic_program.jl")
using .GeneticProgram: GeneticProgram

include("methods/methods.jl")
using .Methods: Methods

end