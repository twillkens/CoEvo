module NSGAII

import ..Evaluators: evaluate

using Random: AbstractRNG, rand
using DataStructures: SortedDict
using StableRNGs: StableRNG
using StatsBase: mean
using LinearAlgebra: dot
using ...Species: AbstractSpecies
using ...Individuals: Individual
using ...Criteria: Criterion, Maximize, Minimize
using ..Evaluators: Evaluation, Evaluator
using ..Evaluators.ScalarFitness: ScalarFitnessEvaluator, ScalarFitnessEvaluation

include("fast_global_kmeans.jl")

include("methods.jl")

include("evaluator.jl")

end