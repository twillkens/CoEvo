module Types

export Identity, IdentityMutator, GeneticProgram, GeneticProgramMutator

include("identity/identity.jl")
using .Identity: Identity, IdentityMutator

include("genetic_program/genetic_program.jl")
using .GeneticProgram: GeneticProgram, GeneticProgramMutator

end