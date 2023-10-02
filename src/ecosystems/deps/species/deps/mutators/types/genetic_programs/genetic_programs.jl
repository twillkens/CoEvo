
module GeneticPrograms

export GeneticProgramMutator, Mutators, Methods

include("mutators.jl")
using .Mutators: Mutators, GeneticProgramMutator

include("methods.jl")
using .Methods: Methods

end