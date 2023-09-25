# Swaps two nodes in the genotype tree
# Updates parent child vectors and root node. If a node is a nonroot terminal with no parent,
# then delete it from the set of terminals an hence the tree. This keeps the number 
# of free terminals from blowing up as evolution progresses.
function swap_node(
    geno::BasicGeneticProgramGenotype, 
    node_gid1::Int, 
    node_gid2::Int,
)
    geno = deepcopy(geno)
    # if the nodes are the same, return the genotype unchanged
    if node_gid1 == node_gid2
        return geno
    end
    # set the parents of the nodes to be swapped
    node1 = get_node(geno, node_gid1)
    node2 = get_node(geno, node_gid2)
    parent_gid1 = node1.parent_gid
    parent_gid2 = node2.parent_gid
    node1.parent_gid = parent_gid2
    node2.parent_gid = parent_gid1

    # if the parents are not nothing, then update their children vector
    if parent_gid2 !== nothing
        parent_node2 = get_node(geno, parent_gid2)
        child_idx = get_child_index(parent_node2, node2)
        parent_node2.child_gids[child_idx] = node1.gid
    end
    if parent_gid1 !== nothing
        parent_node1 = get_node(geno, parent_gid1)
        child_idx = get_child_index(parent_node1, node1)
        parent_node1.child_gids[child_idx] = node2.gid
    end

    # if one node is the root of the execution tree, then update the root to be the other node
    if node_gid1 == geno.root_gid
        geno.root_gid = node_gid2
    elseif node_gid2 == geno.root_gid
        geno.root_gid = node_gid1
    end

    # if a node is a nonroot terminal with no parent, then delete it from the set of terminals
    if node_gid1 in keys(geno.terms) && node1.parent_gid === nothing && node_gid1 !== geno.root_gid
        delete!(geno.terms, node_gid1)
    end
    if node_gid2 in keys(geno.terms) && node2.parent_gid === nothing && node_gid2 !== geno.root_gid
        delete!(geno.terms, node_gid2)
    end
    geno
end

# Selects two nodes at random and swaps them
# The criteria is that two nodes cannot be swapped if they belong to the same lineage
# (i.e. one is an ancestor of the other)
function swap_node(rng::AbstractRNG, ::SpawnCounter, ::BasicGeneticProgramMutator, geno::BasicGeneticProgramGenotype)
    # select a function node at random
    node1 = rand(rng, all_nodes(geno)).second
    lineage_nodes = [get_ancestors(geno, node1); node1; get_descendents(geno, node1)]
    lineage_gids = Set(n.gid for n in lineage_nodes)
    all_node_gids = Set(n.gid for n in values(all_nodes(geno)))
    swappable = setdiff(all_node_gids, lineage_gids)
    if length(swappable) == 0
        return deepcopy(geno)
    end
    node_gid2 = rand(rng, swappable)
    swap_node(geno, node1.gid, node_gid2)
end

function replace_child!(parent_node::ExpressionNodeGene, old_child_node::ExpressionNodeGene, new_child_node::ExpressionNodeGene)
    child_idx = get_child_index(parent_node, old_child_node)
    parent_node.child_gids[child_idx] = new_child_node.gid
end

function replace_child!(parent_gid::Int, old_child_gid::Int, new_child_gid::Int)
    parent_node = get_node(geno, parent_gid)
    old_child_node = get_node(geno, old_child_gid)
    new_child_node = get_node(geno, new_child_gid)
    replace_child(parent_node, old_child_node, new_child_node)
end


