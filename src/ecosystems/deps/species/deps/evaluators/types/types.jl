module Types

export ScalarFitnessEvaluation, ScalarFitnessEvaluator

include("scalar_fitness.jl")
using .ScalarFitness: ScalarFitnessEvaluation, ScalarFitnessEvaluator

end