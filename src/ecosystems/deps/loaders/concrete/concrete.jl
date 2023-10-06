module Concrete

export FiniteStateMachineGenotypeLoader, GnarlNetworkGenotypeLoader
export BasicVectorGenotypeLoader, GeneticProgramGenotypeLoader

include("fsms/fsms.jl")
using .FiniteStateMachines: FiniteStateMachineGenotypeLoader

include("genetic_programs/genetic_programs.jl")
using .GeneticPrograms: GeneticProgramGenotypeLoader
#
include("gnarl_networks/gnarl_networks.jl")
using .GnarlNetworks: GnarlNetworkGenotypeLoader
#
include("vectors/vectors.jl")
using .Vectors: BasicVectorGenotypeLoader    

end