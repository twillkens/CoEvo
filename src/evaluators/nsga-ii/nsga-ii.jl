module NSGAII

import ..Evaluators: create_evaluation

using Random: AbstractRNG, rand
using DataStructures: SortedDict
using StableRNGs: StableRNG
using StatsBase: mean
using LinearAlgebra: dot
using ...Species: AbstractSpecies
using ...Individuals: Individual
using ...Criteria: Criterion, Maximize, Minimize
using ..Evaluators: Evaluation, Evaluator

include("fast_global_kmeans.jl")

include("methods.jl")

include("evaluator.jl")

end