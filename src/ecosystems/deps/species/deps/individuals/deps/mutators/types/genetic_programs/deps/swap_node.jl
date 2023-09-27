export swap_node

using Random: rand, AbstractRNG

using .......CoEvo.Utilities.Counters: Counter
using ..Genotypes: BasicGeneticProgramGenotype
using ..Genotypes.Utilities: get_ancestors, get_descendents, all_nodes

import ..Genotypes.Mutations: swap_node
