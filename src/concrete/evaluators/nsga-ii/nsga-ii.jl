module NSGAII
export NSGAIIEvaluator, NSGAIIEvaluation
export NSGAIIRecord, nsga_sort!, nsga_tournament
export dominates, fast_non_dominated_sort!, crowding_distance_assignment!
export create_records, evaluate

using Random: AbstractRNG, rand
using DataStructures: SortedDict
using StableRNGs: StableRNG
using StatsBase: mean
using LinearAlgebra: dot
using ..Evaluators.ScalarFitness: ScalarFitnessEvaluator, ScalarFitnessEvaluation

include("methods.jl")

#include("distinctions_coarse.jl")
#include("distinctions.jl")

include("evaluator.jl")

end