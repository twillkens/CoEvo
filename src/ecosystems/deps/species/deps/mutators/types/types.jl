module Types

export Identity, IdentityMutator, GeneticPrograms, GeneticProgramMutator, NoiseInjectionMutator

include("identity/identity.jl")
using .Identity: Identity, IdentityMutator

include("noise_injection/noise_injection.jl")
using .NoiseInjection: NoiseInjectionMutator

include("genetic_programs/genetic_programs.jl")
using .GeneticPrograms: GeneticPrograms, GeneticProgramMutator

end