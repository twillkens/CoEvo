
module GeneticProgram

export GeneticProgramMutator

include("mutator.jl")
using .Mutator: Mutator, GeneticProgramMutator

include("methods.jl")
using .Methods: Methods

end