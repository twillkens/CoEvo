export swap_node

using ..Genotypes: BasicGeneticProgramGenotype
using ..Utilities: get_node, get_child_index

"""
    swap_node(geno::BasicGeneticProgramGenotype, node_id1::Int, node_id2::Int) -> BasicGeneticProgramGenotype

Swap two nodes and their subtrees in the genotype. This function makes a deep copy of the 
original genotype and returns
a new genotype with the nodes swapped. 

If a node is a non-root terminal with no parent, it is deleted from the set of terminals, preventing the
number of free terminals from increasing excessively during evolutionary processes.

# Arguments:
- `geno::BasicGeneticProgramGenotype`: The genotype tree to be modified.
- `node_id1::Int`: The ID of the first node to be swapped.
- `node_id2::Int`: The ID of the second node to be swapped.

# Returns:
- A new `BasicGeneticProgramGenotype` with the specified nodes swapped.
"""
function swap_node(geno::BasicGeneticProgramGenotype, node_id1::Int, node_id2::Int)
    geno = deepcopy(geno)

    # Return the genotype unchanged if nodes are the same.
    if node_id1 == node_id2
        return geno
    end

    # Retrieve nodes and their parent IDs.
    node1 = get_node(geno, node_id1)
    node2 = get_node(geno, node_id2)
    parent_id1 = node1.parent_id
    parent_id2 = node2.parent_id

    # Swap parent IDs of the nodes.
    node1.parent_id = parent_id2
    node2.parent_id = parent_id1

    # Update the children vector of the parents, if they exist.
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

    # Update root ID if either node is the root.
    if node_id1 == geno.root_id
        geno.root_id = node_id2
    elseif node_id2 == geno.root_id
        geno.root_id = node_id1
    end

    # Delete non-root terminal nodes with no parents from the set of terminals.
    if node_id1 in keys(geno.terminals) && node1.parent_id === nothing && node_id1 !== geno.root_id
        delete!(geno.terminals, node_id1)
    end

    if node_id2 in keys(geno.terminals) && node2.parent_id === nothing && node_id2 !== geno.root_id
        delete!(geno.terminals, node_id2)
    end

    return geno
end
