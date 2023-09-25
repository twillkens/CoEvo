export swap_node

using Random: rand, AbstractRNG
using .....CoEvo.Utilities.Counters: Counter

# Selects two nodes at random and swaps them
# The criteria is that two nodes cannot be swapped if they belong to the same lineage
# (i.e. one is an ancestor of the other)
function swap_node(
    rng::AbstractRNG, 
    ::Counter, 
    ::BasicGeneticProgramMutator, 
    geno::BasicGeneticProgramGenotype
)
    # select a function node at random
    node1 = rand(rng, all_nodes(geno)).second
    lineage_nodes = [get_ancestors(geno, node1); node1; get_descendents(geno, node1)]
    lineage_ids = Set(n.id for n in lineage_nodes)
    all_node_ids = Set(n.id for n in values(all_nodes(geno)))
    swappable = setdiff(all_node_ids, lineage_ids)
    if length(swappable) == 0
        return deepcopy(geno)
    end
    node_id2 = rand(rng, swappable)
    swap_node(geno, node1.id, node_id2)
end
