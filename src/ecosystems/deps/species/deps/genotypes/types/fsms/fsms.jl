module FiniteStateMachines

export FiniteStateMachineGenotype, FiniteStateMachineGenotypeCreator, Genotypes
export FiniteStateMachineMinimizers

include("genotypes.jl")
using .Genotypes: Genotypes, FiniteStateMachineGenotype, FiniteStateMachineGenotypeCreator

include("minimize.jl")
using .FiniteStateMachineMinimizers: FiniteStateMachineMinimizers

end