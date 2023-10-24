module NSGAII

import ..Evaluators.Interfaces: create_evaluation

using Random: AbstractRNG, rand
using DataStructures: SortedDict
using StableRNGs: StableRNG
using StatsBase: mean
using LinearAlgebra: dot
using ...Species.Abstract: AbstractSpecies
using ...Individuals.Abstract: Individual
using ...Criteria: Criterion, Maximize, Minimize
using ..Evaluators.Abstract: Evaluation, Evaluator

include("fast_global_kmeans.jl")

include("methods.jl")

include("evaluator.jl")

end