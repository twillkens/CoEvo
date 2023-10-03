module Manipulate

export add_function, remove_function, splice_function, swap_node, inject_noise

using Random: AbstractRNG, rand

using ...GeneticPrograms: GeneticProgramGenotype, ExpressionNodeGene
using .......Ecosystems.Utilities.Counters: Counter, next!
using ...Utilities: Terminal, FuncAlias
import ..Methods.Traverse: get_child_index, get_node, get_ancestors

"""
    replace_child!(parent_node::ExpressionNodeGene, old_child_node::ExpressionNodeGene, new_child_node::ExpressionNodeGene)

Replace `old_child_node` with `new_child_node` in the list of children for `parent_node`.
"""
function replace_child!(
    parent_node::ExpressionNodeGene, 
    old_child_node::ExpressionNodeGene, 
    new_child_node::ExpressionNodeGene
)
    child_idx = get_child_index(parent_node, old_child_node)
    parent_node.child_ids[child_idx] = new_child_node.id
end

"""
- A modified genotype with the new function node and its terminals added.

Throws:
- Error if the new node's ID already exists in the genotype.
"""
function add_function(
    geno::GeneticProgramGenotype, 
    newnode_id::Real, 
    newnode_val::Union{FuncAlias},
    newnode_child_ids::Vector{<:Real},
    newnode_child_vals::Vector{<:Terminal},
)
    geno = deepcopy(geno)
    new_child_nodes = [
        ExpressionNodeGene(
            newnode_child_ids[i], 
            newnode_id, 
            newnode_child_vals[i], 
            ExpressionNodeGene[]
        ) 
        for i in 1:length(newnode_child_ids)
    ]
    new_node = ExpressionNodeGene(newnode_id, nothing, newnode_val, newnode_child_ids)
    push!(geno.functions, new_node.id => new_node)
    [push!(geno.terminals, child.id => child) for child in new_child_nodes]
    return geno
end


"""
    remove_function(geno::GeneticProgramGenotype, target_id::Int, substitute_child_id::Int)

Remove a specified function node from a copied version of the genotype. The child node, specified 
to substitute the node to be removed, takes its place in the genotype's execution tree.

Returns:
- A modified genotype with the specified function node removed and replaced with the substitute node.

Throws:
- Error if the `substitute_child_id` is not a child of `target_id`.
"""
function remove_function(
    geno::GeneticProgramGenotype, 
    target_id::Int,
    substitute_child_id::Int,
)
    # Copy the genotype and remove the target node.
    geno = deepcopy(geno)
    target_node = get_node(geno, target_id)
    if substitute_child_id ∉ target_node.child_ids
        throw(ErrorException("Cannot substitute node $substitute_child_id for node $target_id"))
    end
    delete!(geno.functions, target_id)
    for child_id in target_node.child_ids
        child_node = get_node(geno, child_id)
        # If the child is the node picked for substitution, then it takes the place of the 
        # target node to be removed.
        if child_id == substitute_child_id
            # The substitute child becomes the new child of the target's parent.
            substitute_child_node = child_node
            if target_node.parent_id !== nothing
                target_parent_node = get_node(geno, target_node.parent_id)
                target_child_idx = get_child_index(target_parent_node, target_node)
                target_parent_node.child_ids[target_child_idx] = substitute_child_id
                substitute_child_node.parent_id = target_parent_node.id
            else
                # Remove parent of substitute_child
                substitute_child_node.parent_id = nothing
                # If target is the root of the execution tree, then substitute_child becomes 
                # the new root.
                if geno.root_id == target_id
                    geno.root_id = substitute_child_id
                # Otherwise, if the substitute is a terminal and is not the new root of the 
                # execution tree, remove it
                elseif substitute_child_id in keys(geno.terminals)
                    delete!(geno.terminals, substitute_child_id)
                end
            end
        # If the child is a function and not the substitute, disconnect the child from the target. 
        elseif child_id in keys(geno.functions)
            child_node.parent_id = nothing
        # If the child is a terminal, remove it from the set of terminals.
        else
            delete!(geno.terminals, child_id)
        end
    end
    return geno
end


"""
    splice_function(geno::GeneticProgramGenotype, segment_top_id::Int, 
                    segment_bottom_child_id::Int, target_id::Int)

Splice the execution tree of the genotype at the specified points. The function takes a 
segment of the execution tree, represented by `segment_top` and `segment_bottom_child`, 
and splice it between a node taken from a separate linearge (`target`) and the other node's parent.


Returns:
- A modified genotype with the specified splicing applied.

Throws:
- Error if any of the node IDs are invalid or if the splicing operation cannot be completed.
"""
function splice_function(
    geno::GeneticProgramGenotype, 
    segment_top_id::Int, 
    segment_bottom_child_id::Int,
    target_id::Int,
)
    if segment_top_id == target_id
        throw(ErrorException("Cannot splice function: segment top and target are the same node"))
    end
    geno = deepcopy(geno)

    segment_top = get_node(geno, segment_top_id)
    segment_top_parent = get_node(geno, segment_top.parent_id)
    segment_bottom_child = get_node(geno, segment_bottom_child_id)
    segment_bottom = get_node(geno, segment_bottom_child.parent_id)

    target = get_node(geno, target_id)
    target_parent = get_node(geno, target.parent_id)

    if segment_top in get_ancestors(geno, target) || target in get_ancestors(geno, segment_top)
        throw(ErrorException("Cannot splice function: segment top and target share direct ancestry"))
    end

    # The segment top replaces the target as the child of the target's parent.
    if target_parent !== nothing
        segment_top.parent_id = target_parent.id
        replace_child!(target_parent, target, segment_top)
    else
    # If the target has no parent, then the segment top becomes a root. 
        segment_top.parent_id = nothing
    end

    # The target then is attached to the segment bottom, replacing the segment bottom's child,
    target.parent_id = segment_bottom.id
    replace_child!(segment_bottom, segment_bottom_child, target)

    # The child of the segment bottom then becomes the child of the segment top's parent.
    segment_bottom_child.parent_id = segment_top_parent === nothing ? nothing : segment_top_parent.id
    if segment_top_parent !== nothing
        replace_child!(segment_top_parent, segment_top, segment_bottom_child)
    end

    # If the target was the root, then the segment top becomes the new execution root.
    if target_id == geno.root_id
        geno.root_id = segment_top.id
    # If the segment top was the root, then ownership of the execution root is passed to the 
    # root of the target's subtree.
    elseif segment_top.id == geno.root_id
        ancestors = get_ancestors(geno, segment_top)
        if length(ancestors) > 0
            target_subtree_root = ancestors[end]
            geno.root_id = target_subtree_root.id
        end
    end
    # If the segment bottom's child is a terminal, remove it.
    if segment_bottom_child_id in keys(geno.terminals) && 
            segment_bottom_child.parent_id === nothing && 
            segment_bottom_child_id !== geno.root_id
        delete!(geno.terminals, segment_bottom_child_id)
    end
    return geno
end


"""
    swap_node(geno::GeneticProgramGenotype, node_id1::Int, node_id2::Int) -> GeneticProgramGenotype

Swap two nodes and their subtrees in the genotype. This function makes a deep copy of the 
original genotype and returns
a new genotype with the nodes swapped. 

If a node is a non-root terminal with no parent, it is deleted from the set of terminals, preventing the
number of free terminals from increasing excessively during evolutionary processes.

# Arguments:
- `geno::GeneticProgramGenotype`: The genotype tree to be modified.
- `node_id1::Int`: The ID of the first node to be swapped.
- `node_id2::Int`: The ID of the second node to be swapped.

# Returns:
- A new `GeneticProgramGenotype` with the specified nodes swapped.
"""
function swap_node(geno::GeneticProgramGenotype, node_id1::Int, node_id2::Int)
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

function inject_noise(geno::GeneticProgramGenotype, noisedict::Dict{Int, Float64})
    geno = deepcopy(geno)
    for (id, noise) in noisedict
        if !haskey(geno.terminals, id)
            throw(ErrorException("Cannot inject noise into node $id"))
        elseif !isa(geno.terminals[id].val, Float64)
            throw(ErrorException("Cannot inject noise into node $id"))
        else
            node = geno.terminals[id]
            node.val += noise
        end
    end
    return geno
end

end