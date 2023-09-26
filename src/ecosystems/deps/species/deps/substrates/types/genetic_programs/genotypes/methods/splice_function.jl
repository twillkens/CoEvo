export splice_function

"""
    splice_function(geno::BasicGeneticProgramGenotype, segment_top_id::Int, 
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
    geno::BasicGeneticProgramGenotype, 
    segment_top_id::Int, 
    segment_bottom_child_id::Int,
    target_id::Int,
)
    if segment_top_id == target_id
        throw(ErrorException("Cannot splice function: segment top and target are the same node"))
    end
    geno = deepcopy(geno)

    segment_top_parent = get_node(geno, segment_top.parent_id)
    segment_top = get_node(geno, segment_top_id)
    segment_bottom = get_node(geno, segment_bottom_child.parent_id)
    segment_bottom_child = get_node(geno, segment_bottom_child_id)

    target_parent = get_node(geno, target.parent_id)
    target = get_node(geno, target_id)

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
        target_subtree_root = ancestors[end]
        geno.root_id = length(ancestors) > 0 ? target_subtree_root.id : segment_top.id
    end
    # If the segment bottom's child is a terminal, remove it.
    if segment_bottom_child_id in keys(geno.terminals) && 
            segment_bottom_child.parent_id === nothing && 
            segment_bottom_child_id !== geno.root_id
        delete!(geno.terminals, segment_bottom_child_id)
    end
    return geno
end
