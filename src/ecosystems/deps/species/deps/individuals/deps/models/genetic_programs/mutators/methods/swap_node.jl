export swap_node

using Random: rand, AbstractRNG

using .......CoEvo.Utilities.Counters: Counter
using ..Genotypes: BasicGeneticProgramGenotype
using ..Genotypes.Utilities: get_ancestors, get_descendents, all_nodes

import ..Genotypes.Mutations: swap_node

"""
    swap_node(rng::AbstractRNG, ::Counter, ::BasicGeneticProgramMutator, geno::BasicGeneticProgramGenotype)

Swap two randomly selected nodes in the genotype tree. Nodes that belong to the same lineage (one is an ancestor of the other) cannot be swapped.

# Arguments:
- `rng::AbstractRNG`: Random number generator.
- `::Counter`: Counter for unique gene IDs.
- `::BasicGeneticProgramMutator`: Mutator operations for genetic programming.
- `geno::BasicGeneticProgramGenotype`: Genotype to swap nodes in.

# Returns:
- A new `BasicGeneticProgramGenotype` with the specified nodes swapped.
"""
function swap_node(
    rng::AbstractRNG, 
    ::Counter, 
    ::BasicGeneticProgramMutator, 
    geno::BasicGeneticProgramGenotype
)
    # Select a node at random.
    node1 = rand(rng, all_nodes(geno)).second
    # Find the nodes that do not belong to the lineage of node1.
    lineage_nodes = [get_ancestors(geno, node1); node1; get_descendents(geno, node1)]
    lineage_ids = Set(n.id for n in lineage_nodes)
    all_node_ids = Set(n.id for n in values(all_nodes(geno)))
    swappable = setdiff(all_node_ids, lineage_ids)
    if length(swappable) == 0
        return deepcopy(geno)
    end
    # Select a second node at random from the set of swappable nodes.
    node_id2 = rand(rng, swappable)
    swap_node(geno, node1.id, node_id2)
end
