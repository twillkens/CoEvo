module Evaluators

export Null, ScalarFitness, NSGAII

using Random: AbstractRNG
using DataStructures: SortedDict
using ..Species: AbstractSpecies

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("null/null.jl")
using .Null: Null

include("scalar_fitness/scalar_fitness.jl")
using .ScalarFitness: ScalarFitness

include("nsga-ii/nsga-ii.jl")
using .NSGAII: NSGAII

end
