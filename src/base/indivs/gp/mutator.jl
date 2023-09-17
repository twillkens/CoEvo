export GPMutator
# Default mutator for GPGenos
Base.@kwdef struct GPMutator <: Mutator
    # Number of structural changes to perform per generation
    nchanges::Int = 1
    # Uniform probability of each type of structural change
    probs::Dict{Function, Float64} = Dict(
        addfunc => 1 / 3,
        rmfunc => 1 / 3,
        swapnode => 1 / 3,
    )
    terminals::Dict{Terminal, Int} = Dict(
        :read => 1, 
        0.0 => 1, 
    )
    functions::Dict{FuncAlias, Int} = Dict([
        (psin, 1), 
        (+, 2), 
        (-, 2), 
        (*, 2),
        (iflt, 4),
    ])
    noise_std::Float64 = 0.1
end
# Make a copy of the genotype and create the new function node and its terminals
# before adding to the genotype func and term dicts.
# By default a new function and its terminals are disconnected from the rest of the 
# genotype and execution tree. It may be added later through a swap operation
function addfunc(
    geno::GPGeno, 
    newnode_gid::Real, 
    newnode_val::Union{FuncAlias},
    newnode_child_gids::Vector{<:Real},
    newnode_child_vals::Vector{<:Terminal},
)
    geno = deepcopy(geno)
    new_child_nodes = [
        ExprNode(
            newnode_child_gids[i], 
            newnode_gid, 
            newnode_child_vals[i], 
            ExprNode[]
        ) 
        for i in 1:length(newnode_child_gids)
    ]
    new_node = ExprNode(newnode_gid, nothing, newnode_val, newnode_child_gids)
    push!(geno.funcs, new_node.gid => new_node)
    [push!(geno.terms, child.gid => child) for child in new_child_nodes]
    geno
end

# Generate a random function node along with its terminals add it to a new copy of the genotype
function addfunc(rng::AbstractRNG, sc::SpawnCounter, m::GPMutator, geno::GPGeno)
    newnode_gid = gid!(sc) # Increment spawn counter to find unique gene id
    newnode_val, ndim = rand(rng, m.functions) # Choose a random function and number of args
    new_child_gids = [gid!(sc) for _ in 1:ndim] # Generate unique gene ids for the children
    new_child_vals = [rand(rng, keys(m.terminals)) for _ in 1:ndim] # Choose random terminals
    # The new node is added to the genotype without a parent
    addfunc(geno, newnode_gid, newnode_val, new_child_gids, new_child_vals)
end

function get_child_index(parent_node::ExprNode, child_node::ExprNode)
    findfirst(x -> x == child_node.gid, parent_node.child_gids)
end

# Remove a function node from the genotype. One of the children of the node to be removed
# is passed as an argument and is used to substitute the node to be removed.
# If the parent of to_remove exists, then the child to substitute becomes a child of the parent
# at the appropriate index. If the parent of to_remove does not exist, then the child's parent
# is removed. If to_remove is the root of the execution tree, then to_substitute becomes the new
# root. If to_substitute is a terminal and is not the new root of the execution tree, then it is
# removed from the set of terminals.
# All other children of to_remove are disconnected from the parent if they are functions
# and deleted from the set of terminals if they are terminals.
function rmfunc(
    geno::GPGeno, 
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
function rmfunc(rng::AbstractRNG, ::GPMutator, geno::GPGeno)
    if length(geno.funcs) == 0
        return deepcopy(geno)
    end
    # select a function node at random
    to_remove = rand(rng, geno.funcs).second
    # choose node to substitute at random
    to_substitute_gid = rand(rng, to_remove.child_gids)
    # execute removal
    rmfunc(geno, to_remove.gid, to_substitute_gid)
end

# Swaps two nodes in the genotype tree
# Updates parent child vectors and root node. If a node is a nonroot terminal with no parent,
# then delete it from the set of terminals an hence the tree. This keeps the number 
# of free terminals from blowing up as evolution progresses.
function swapnode(
    geno::GPGeno, 
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
    if node_gid1 in keys(geno.terms) && node1.parent_gid === nothing && node1 !== geno.root_gid
        delete!(geno.terms, node_gid1)
    end
    if node_gid2 in keys(geno.terms) && node2.parent_gid === nothing && node2 !== geno.root_gid
        delete!(geno.terms, node_gid2)
    end
    geno
end

# Selects two nodes at random and swaps them
# The criteria is that two nodes cannot be swapped if they belong to the same lineage
# (i.e. one is an ancestor of the other)
function swapnode(rng::AbstractRNG, ::GPMutator, geno::GPGeno)
    # select a function node at random
    node1 = rand(rng, geno.funcs).second
    lineage_nodes = [get_ancestors(geno, node1); node1; get_descendents(geno, node1)]
    lineage_gids = Set(n.gid for n in lineage_nodes)
    all_node_gids = Set(n.gid for n in values(all_nodes(geno)))
    swappable = setdiff(all_node_gids, lineage_gids)
    if length(swappable) == 0
        return deepcopy(geno)
    end
    node_gid2 = rand(rng, swappable)
    swapnode(geno, node1.gid, node_gid2)
end

# Mutate the genotype by adding random noise to real-valued terminals
function inject_noise(geno::GPGeno, noisedict::Dict{Int, Float64})
    geno = deepcopy(geno)
    for (gid, noise) in noisedict
        node = get_node(geno, gid)
        if isa(node.val, Float64)
            node.val += noise
        else
            throw(ErrorException("Cannot inject noise into non-Float64 node"))
        end
    end
    geno
end

# Generate a dictionary of random noise values for each real-valued terminal in the genotype
# and inject the noise into a copy of the genotype. Uses the GPMutator noise_std field.
function inject_noise(rng::AbstractRNG, m::GPMutator, geno::GPGeno)
    noisedict = Dict{Int, Float64}()
    injectable_gids = [gid for (gid, node) in geno.terms if isa(node.val, Float64)]
    noisevec = randn(rng, length(injectable_gids)) * m.noise_std
    noisedict = Dict(zip(injectable_gids, noisevec))
    inject_noise(geno, noisedict)
end
