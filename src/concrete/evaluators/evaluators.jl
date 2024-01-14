module Evaluators

export Null, ScalarFitness, NSGAII#, AdaptiveArchive

include("null/null.jl")
using .Null: Null

include("scalar_fitness/scalar_fitness.jl")
using .ScalarFitness: ScalarFitness

include("nsga-ii/nsga-ii.jl")
using .NSGAII: NSGAII

end
