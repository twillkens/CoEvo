module Archivers

export Globals, Ecosystems, GenotypeSize, Fitness# , Modes


include("utilities/utilities.jl")

include("globals/globals.jl")
using .Globals: Globals

include("ecosystems/ecosystems.jl")
using .Ecosystems: Ecosystems

include("genotype_size/genotype_size.jl")
using .GenotypeSize: GenotypeSize

include("fitness/fitness.jl")
using .Fitness: Fitness

#include("modes/modes.jl")
#using .Modes: Modes

end