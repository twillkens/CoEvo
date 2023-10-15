module Types

export Identity, IdentityMutator, NoiseInjectionMutator
export GnarlNetworks, GnarlNetworkMutator, FiniteStateMachineMutators, FiniteStateMachineMutator
export FunctionGraphMutators, FunctionGraphMutator
#export GeneticPrograms, GeneticProgramMutator

include("identity/identity.jl")
using .Identity: Identity, IdentityMutator

include("noise_injection/noise_injection.jl")
using .NoiseInjection: NoiseInjectionMutator

#include("genetic_programs/genetic_programs.jl")
#using .GeneticPrograms: GeneticPrograms, GeneticProgramMutator

include("gnarl/gnarl.jl")
using .GnarlNetworks: GnarlNetworks, GnarlNetworkMutator

include("fsms/fsms.jl")
using .FiniteStateMachineMutators: FiniteStateMachineMutators, FiniteStateMachineMutator

include("function_graphs/function_graphs.jl")
using .FunctionGraphMutators: FunctionGraphMutators, FunctionGraphMutator

end