export remove_function

using Random: AbstractRNG, rand

using ......CoEvo.Utilities.Counters: Counter
using ..Genotypes: BasicGeneticProgramGenotype
using ..Mutators: BasicGeneticProgramMutator

import ..Genotypes.Mutations: remove_function

"""
    remove_function(rng::AbstractRNG, ::Counter, ::BasicGeneticProgramMutator, geno::BasicGeneticProgramGenotype)

Randomly select and remove a function node from the genotype. If the genotype has no function nodes, a copy of the original genotype is returned.

# Arguments:
- `rng::AbstractRNG`: Random number generator.
- `::Counter`: Counter for unique gene IDs.
- `::BasicGeneticProgramMutator`: Mutator operations for genetic programming.
- `geno::BasicGeneticProgramGenotype`: Genotype to remove function from.

# Returns:
- A new `BasicGeneticProgramGenotype` with the selected function node removed.
"""
function remove_function(
    rng::AbstractRNG, 
    ::Counter, 
    ::BasicGeneticProgramMutator, 
    geno::BasicGeneticProgramGenotype
)
    if length(geno.functions) == 0
        return deepcopy(geno)
    end
    # Select a function node at random.
    to_remove = rand(rng, geno.functions).second
    # Choose node to substitute at random.
    to_substitute_id = rand(rng, to_remove.child_ids)
    # Execute removal deterministicaly.
    remove_function(geno, to_remove.id, to_substitute_id)
end