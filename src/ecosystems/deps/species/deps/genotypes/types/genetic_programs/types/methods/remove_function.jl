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
    to_remove_gid::Int,
    to_substitute_gid::Int,
)
    # copy the genotype and remove the target node
    geno = deepcopy(geno)
    to_remove_node = get_node(geno, to_remove_gid)
    if to_substitute_gid ∉ to_remove_node.child_gids
        throw(ErrorException("Cannot substitute node $to_substitute_gid for node $to_remove_gid"))
    end
    delete!(geno.funcs, to_remove_gid)
    for child_gid in to_remove_node.child_gids
        child_node = get_node(geno, child_gid)
        # If the child is the node picked for substitution, then substitute it for the node
        # to be removed
        if child_gid == to_substitute_gid
            # If to_remove has a parent, then to_substitute becomes a child of the parent
            to_substitute_node = child_node
            if to_remove_node.parent_gid !== nothing
                grandparent_node = get_node(geno, to_remove_node.parent_gid)
                to_remove_child_idx = get_child_index(grandparent_node, to_remove_node)
                grandparent_node.child_gids[to_remove_child_idx] = to_substitute_gid
                to_substitute_node.parent_gid = grandparent_node.gid
            else
                # Remove parent of to_substitute
                to_substitute_node.parent_gid = nothing
                # If to_remove is the root of the execution tree, then to_substitute becomes 
                # the new root
                if geno.root_gid == to_remove_gid
                    geno.root_gid = to_substitute_gid
                # If the child to substitute is a terminal and is not the new root of the 
                # execution tree, remove it
                elseif to_substitute_gid in keys(geno.terms)
                    delete!(geno.terms, to_substitute_gid)
                end
            end
        # If the child is a function and not the substitute, disconnect the child from the parent 
        elseif child_gid in keys(geno.funcs)
            child_node.parent_gid = nothing
        # If the child is a terminal, remove it from the set of terminals
        else
            delete!(geno.terms, child_gid)
        end
    end
    geno
end

# Randomly select a function node and one of its children and remove the function node
# If the genotype has no function nodes, then return a copy of the genotype
function remove_function(rng::AbstractRNG, ::SpawnCounter, ::BasicGeneticProgramMutator, geno::BasicGeneticProgramGenotype)
    if length(geno.funcs) == 0
        return deepcopy(geno)
    end
    # select a function node at random
    to_remove = rand(rng, geno.funcs).second
    # choose node to substitute at random
    to_substitute_gid = rand(rng, to_remove.child_gids)
    # execute removal
    remove_function(geno, to_remove.gid, to_substitute_gid)
end