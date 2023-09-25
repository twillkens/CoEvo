export remove_function

# Remove a function node from the genotype. One of the children of the node to be removed
# is passed as an argument and is used to substitute the node to be removed.
# If the parent of to_remove exists, then the child to substitute becomes a child of the parent
# at the appropriate index. If the parent of to_remove does not exist, then the child's parent
# is removed. If to_remove is the root of the execution tree, then to_substitute becomes the new
# root. If to_substitute is a terminal and is not the new root of the execution tree, then it is
# removed from the set of terminals.
# All other children of to_remove are disconnected from the parent if they are functions
# and deleted from the set of terminals if they are terminals.
function remove_function(
    geno::BasicGeneticProgramGenotype, 
    to_remove_id::Int,
    to_substitute_id::Int,
)
    # copy the genotype and remove the target node
    geno = deepcopy(geno)
    to_remove_node = get_node(geno, to_remove_id)
    if to_substitute_id ∉ to_remove_node.child_ids
        throw(ErrorException("Cannot substitute node $to_substitute_id for node $to_remove_id"))
    end
    delete!(geno.functions, to_remove_id)
    for child_id in to_remove_node.child_ids
        child_node = get_node(geno, child_id)
        # If the child is the node picked for substitution, then substitute it for the node
        # to be removed
        if child_id == to_substitute_id
            # If to_remove has a parent, then to_substitute becomes a child of the parent
            to_substitute_node = child_node
            if to_remove_node.parent_id !== nothing
                grandparent_node = get_node(geno, to_remove_node.parent_id)
                to_remove_child_idx = get_child_index(grandparent_node, to_remove_node)
                grandparent_node.child_ids[to_remove_child_idx] = to_substitute_id
                to_substitute_node.parent_id = grandparent_node.id
            else
                # Remove parent of to_substitute
                to_substitute_node.parent_id = nothing
                # If to_remove is the root of the execution tree, then to_substitute becomes 
                # the new root
                if geno.root_id == to_remove_id
                    geno.root_id = to_substitute_id
                # If the child to substitute is a terminal and is not the new root of the 
                # execution tree, remove it
                elseif to_substitute_id in keys(geno.terminals)
                    delete!(geno.terminals, to_substitute_id)
                end
            end
        # If the child is a function and not the substitute, disconnect the child from the parent 
        elseif child_id in keys(geno.functions)
            child_node.parent_id = nothing
        # If the child is a terminal, remove it from the set of terminals
        else
            delete!(geno.terminals, child_id)
        end
    end
    geno
end
