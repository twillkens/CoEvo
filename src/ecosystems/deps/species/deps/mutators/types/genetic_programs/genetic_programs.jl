
module GeneticPrograms

export GeneticProgramMutator, Mutators, Methods

include("methods/methods.jl")
using .Methods: Methods

include("mutators.jl")
using .Mutators: Mutators, GeneticProgramMutator

end