export swap_node

# Swaps two nodes in the genotype tree
# Updates parent child vectors and root node. If a node is a nonroot terminal with no parent,
# then delete it from the set of terminals an hence the tree. This keeps the number 
# of free terminals from blowing up as evolution progresses.
function swap_node(
    geno::BasicGeneticProgramGenotype, 
    node_id1::Int, 
    node_id2::Int,
)
    geno = deepcopy(geno)
    # if the nodes are the same, return the genotype unchanged
    if node_id1 == node_id2
        return geno
    end
    # set the parents of the nodes to be swapped
    node1 = get_node(geno, node_id1)
    node2 = get_node(geno, node_id2)
    parent_id1 = node1.parent_id
    parent_id2 = node2.parent_id
    node1.parent_id = parent_id2
    node2.parent_id = parent_id1

    # if the parents are not nothing, then update their children vector
    if parent_id2 !== nothing
        parent_node2 = get_node(geno, parent_id2)
        child_idx = get_child_index(parent_node2, node2)
        parent_node2.child_ids[child_idx] = node1.id
    end
    if parent_id1 !== nothing
        parent_node1 = get_node(geno, parent_id1)
        child_idx = get_child_index(parent_node1, node1)
        parent_node1.child_ids[child_idx] = node2.id
    end

    # if one node is the root of the execution tree, then update the root to be the other node
    if node_id1 == geno.root_id
        geno.root_id = node_id2
    elseif node_id2 == geno.root_id
        geno.root_id = node_id1
    end

    # if a node is a nonroot terminal with no parent, then delete it from the set of terminals
    if node_id1 in keys(geno.terminals) && node1.parent_id === nothing && node_id1 !== geno.root_id
        delete!(geno.terminals, node_id1)
    end
    if node_id2 in keys(geno.terminals) && node2.parent_id === nothing && node_id2 !== geno.root_id
        delete!(geno.terminals, node_id2)
    end
    geno
end
