module Types

export Identity, IdentityMutator, GeneticPrograms, GeneticProgramMutator

include("identity/identity.jl")
using .Identity: Identity, IdentityMutator

include("genetic_programs/genetic_programs.jl")
using .GeneticPrograms: GeneticPrograms, GeneticProgramMutator

end