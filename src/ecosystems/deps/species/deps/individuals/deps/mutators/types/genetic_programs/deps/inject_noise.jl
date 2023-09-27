export inject_noise

using Random: AbstractRNG, randn

using .......CoEvo.Utilities.Counters: Counter
using ..Genotypes: BasicGeneticProgramGenotype
using ..Mutators: BasicGeneticProgramMutator

import ..Genotypes.Mutations: inject_noise
