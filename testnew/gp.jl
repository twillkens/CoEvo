using StableRNGs: StableRNG
using DataStructures: OrderedDict
using Test

include("../src/CoEvo.jl")
using .CoEvo
using .CoEvo.Ecosystems.Species.Substrates.GeneticPrograms: BasicGeneticProgramGenotypeConfiguration

BasicGeneticProgramGenotypeConfiguration()(StableRNG(42), Counter())
#sing .CoEvo.Ecosystems.Jobs.Domains.Problems.NumbersGame: NumbersGameProblem, interact
#using .CoEvo.Ecosystems.Observations: OutcomeObservationConfiguration
#using .CoEvo.Ecosystems.Species.Reporters: CohortMetricReporter
#using .CoEvo.Utilities.Metrics: GenotypeSum, GenotypeSize, EvaluationFitness
#using .CoEvo.Utilities.Counters: Counter

# function get_submodule_recursive(mod::Module, submodule_symbol::Symbol)
#     if hasproperty(mod, submodule_symbol)
#         return getproperty(mod, submodule_symbol)
#     else
#         println("there")
#         for submod in names(mod, all=true)
#             submod_name = Symbol(mod, :., submod)
#             submod = getproperty(mod, submod_name)
#             if isa(submod, Module)
#                 result = get_submodule_recursive(submod, submodule_symbol)
#                 if result !== nothing
#                     return result
#                 end
#             end
#         end
#     end
#     return nothing
# end


# function dummygeno()
#     # Just a sample GPGeno object to use for tests.
#     root = ExprNode(1, nothing, +, [2, 3])
#     node2 = ExprNode(2, 1, 2.0)
#     node3 = ExprNode(3, 1, 3.0)
#     geno = GPGeno(1, Dict(1 => root), Dict(2 => node2, 3 => node3))
#     return geno
# end