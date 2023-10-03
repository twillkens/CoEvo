module Types

export Null, ScalarFitness, Disco

include("null/null.jl")
using .Null: Null

include("scalar_fitness/scalar_fitness.jl")
using .ScalarFitness: ScalarFitness

include("disco/disco.jl")
using .Disco: Disco

end