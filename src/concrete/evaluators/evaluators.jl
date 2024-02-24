module Evaluators

export Null, ScalarFitness, NSGAII, Disco, Redisco, HillClimber#, AdaptiveArchive

include("null/null.jl")
using .Null: Null

include("scalar_fitness/scalar_fitness.jl")
using .ScalarFitness: ScalarFitness

include("nsga-ii/nsga-ii.jl")
using .NSGAII: NSGAII

#include("distinction/distinction.jl")
#using .Distinction: Distinction

include("disco/disco.jl")
using .Disco: Disco

include("redisco/redisco.jl")
using .Redisco: Redisco

include("hillclimber/hillclimber.jl")
using .HillClimber: HillClimber

include("dodo/dodo.jl")
using .Dodo: Dodo

end