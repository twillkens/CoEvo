module NSGAII

using Random: AbstractRNG, rand
using DataStructures: SortedDict
using StableRNGs: StableRNG
using StatsBase: mean
using LinearAlgebra: dot
using ..Evaluators.ScalarFitness: ScalarFitnessEvaluator, ScalarFitnessEvaluation

include("methods.jl")

include("evaluator.jl")

end