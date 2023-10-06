module Genotypes

export FiniteStateMachines, GeneticPrograms, GnarlNetworks, Vectors

include("fsms/fsms.jl")
using .FiniteStateMachines: FiniteStateMachines

include("genetic_programs/genetic_programs.jl")
using .GeneticPrograms: GeneticPrograms

include("gnarl_networks/gnarl_networks.jl")
using .GnarlNetworks: GnarlNetworks

include("vectors/vectors.jl")
using .Vectors: Vectors

end