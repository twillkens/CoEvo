export remove_function

"""
    remove_function(geno::BasicGeneticProgramGenotype, target_id::Int, substitute_child_id::Int)

Remove a specified function node from a copied version of the genotype. The child node, specified 
to substitute the node to be removed, takes its place in the genotype's execution tree.

Returns:
- A modified genotype with the specified function node removed and replaced with the substitute node.

Throws:
- Error if the `substitute_child_id` is not a child of `target_id`.
"""
function remove_function(
    geno::BasicGeneticProgramGenotype, 
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
    geno
end
