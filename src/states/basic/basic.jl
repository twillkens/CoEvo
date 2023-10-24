module Basic

export BasicCoevolutionaryState, BasicCoevolutionaryStateCreator

using Base: @kwdef
using Random: AbstractRNG
using DataStructures: SortedDict
using ...Counters: Counter
using ...Genotypes: get_size, minimize
using ...Species: AbstractSpecies
using ...Evaluators: Evaluation
using ...Evaluators.Null: NullEvaluation
using ...Observers: Observation
using ...Metrics: measure
using ...Metrics.Evaluations: TestBasedFitness, AllSpeciesFitness
using ...Metrics.Genotypes: GenotypeSum, GenotypeSize
using ...Metrics.Common: AllSpeciesIdentity
using ...Measurements.Common: AllSpeciesMeasurement
using ...Measurements.Statistical: BasicStatisticalMeasurement, GroupStatisticalMeasurement
using ..States: State, StateCreator

include("state.jl")

include("measurements.jl")

end