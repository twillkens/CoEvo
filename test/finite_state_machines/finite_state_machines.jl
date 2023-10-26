@testset "FiniteStateMachines" begin

println("Starting tests for FiniteStateMachines and LinguisticPredictionGame...")

include("mutate.jl")
include("minimize.jl")
include("equals.jl")
include("simulate.jl")
#include("evolve.jl")

println("Finished tests for FiniteStateMachines and LinguisticPredictionGame.")

end