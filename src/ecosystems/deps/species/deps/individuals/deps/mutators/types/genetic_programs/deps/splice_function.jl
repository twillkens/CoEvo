export splice_function

using Random: rand, AbstractRNG

using .......CoEvo.Utilities.Counters: Counter
using ..Genotypes: BasicGeneticProgramGenotype
using ..Genotypes.Utilities: get_ancestors, get_descendents, all_nodes
using ..Mutators: BasicGeneticProgramMutator

import ..Genotypes.Mutations: splice_function
