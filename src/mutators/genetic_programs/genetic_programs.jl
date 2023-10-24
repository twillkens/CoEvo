module GeneticPrograms

export add_function, remove_function, swap_node, splice_function, inject_noise, identity

import ..Mutators: mutate

using Random: AbstractRNG, rand
using StatsBase: sample, Weights
using ...Counters: Counter, count!
using ...Genotypes.GeneticPrograms: Terminal, FuncAlias, ExpressionNode
using ...Genotypes.GeneticPrograms: GeneticProgramGenotype, all_nodes, get_ancestors
using ...Genotypes.GeneticPrograms: get_descendents, get_node, get_child_index
using ...Genotypes.GeneticPrograms: protected_sine, if_less_then_else, protected_cosine, protected_division
using ..Mutators: Mutator

function replace_child!(
    parent_node::ExpressionNode, 
    old_child_node::ExpressionNode, 
    new_child_node::ExpressionNode
)
    child_idx = get_child_index(parent_node, old_child_node)
    parent_node.child_ids[child_idx] = new_child_node.id
end

function identity(
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    geno::GeneticProgramGenotype,
    functions::Dict{FuncAlias, Int},
    terminals::Dict{Terminal, Int},
    ::Float64,
)
    return geno
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
        ExpressionNode(
            newnode_child_ids[i], 
            newnode_id, 
            newnode_child_vals[i], 
            Int[]
        ) 
        for i in 1:length(newnode_child_ids)
    ]
    new_node = ExpressionNode(newnode_id, nothing, newnode_val, newnode_child_ids)
    push!(geno.functions, new_node.id => new_node)
    [push!(geno.terminals, child.id => child) for child in new_child_nodes]
    return geno
end

"""
    add_function(rng::AbstractRNG, gene_id_counter::Counter, mutator::GeneticProgramMutator, geno::GeneticProgramGenotype)

Generate a random function node along with its associated terminals, and add them to a new copy 
of the genotype.

# Arguments:
- `rng::AbstractRNG`: Random number generator.
- `gene_id_counter::Counter`: Counter for unique gene IDs.
- `mutator::GeneticProgramMutator`: The mutator containing function and terminal sets.
- `geno::GeneticProgramGenotype`: The genotype tree to be modified.

# Returns:
- A modified `GeneticProgramGenotype` with the new function node added.
"""
function add_function(
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    geno::GeneticProgramGenotype,
    functions::Dict{FuncAlias, Int},
    terminals::Dict{Terminal, Int},
    ::Float64,
)
    newnode_id = count!(gene_id_counter) # Increment spawn counter to find unique gene id
    newnode_val, n_arguments = rand(rng, functions) # Choose a random function and number of args
    new_child_ids = count!(gene_id_counter, n_arguments)
    new_child_vals = Terminal[rand(rng, keys(terminals)) for _ in 1:n_arguments] # Choose random terminals
    # The new node is added to the genotype without a parent
    add_function(geno, newnode_id, newnode_val, new_child_ids, new_child_vals)
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
    remove_function(rng::AbstractRNG, ::Counter, ::GeneticProgramMutator, geno::GeneticProgramGenotype)

Randomly select and remove a function node from the genotype. If the genotype has no function nodes, a copy of the original genotype is returned.

# Arguments:
- `rng::AbstractRNG`: Random number generator.
- `::Counter`: Counter for unique gene IDs.
- `::GeneticProgramMutator`: Mutator operations for genetic programming.
- `geno::GeneticProgramGenotype`: Genotype to remove function from.

# Returns:
- A new `GeneticProgramGenotype` with the selected function node removed.
"""
function remove_function(
    rng::AbstractRNG, 
    ::Counter, 
    geno::GeneticProgramGenotype,
    functions::Dict{FuncAlias, Int},
    terminals::Dict{Terminal, Int},
    ::Float64,
)
    if length(geno.functions) == 0
        return deepcopy(geno)
    end
    # Select a function node at random.
    to_remove = rand(rng, geno.functions).second
    # Choose node to substitute at random.
    to_substitute_id = rand(rng, to_remove.child_ids)
    # Execute removal deterministicaly.
    remove_function(geno, to_remove.id, to_substitute_id)
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
"""
    swap_node(rng::AbstractRNG, ::Counter, ::GeneticProgramMutator, geno::GeneticProgramGenotype)

Swap two randomly selected nodes in the genotype tree. Nodes that belong to the same lineage (one is an ancestor of the other) cannot be swapped.

# Arguments:
- `rng::AbstractRNG`: Random number generator.
- `::Counter`: Counter for unique gene IDs.
- `::GeneticProgramMutator`: Mutator operations for genetic programming.
- `geno::GeneticProgramGenotype`: Genotype to swap nodes in.

# Returns:
- A new `GeneticProgramGenotype` with the specified nodes swapped.
"""
function swap_node(
    rng::AbstractRNG, 
    ::Counter, 
    geno::GeneticProgramGenotype,
    functions::Dict{FuncAlias, Int},
    terminals::Dict{Terminal, Int},
    ::Float64,
)
    # Select a node at random.
    node1 = rand(rng, all_nodes(geno)).second
    # Find the nodes that do not belong to the lineage of node1.
    lineage_nodes = [get_ancestors(geno, node1); node1; get_descendents(geno, node1)]
    lineage_ids = Set(n.id for n in lineage_nodes)
    all_node_ids = Set(n.id for n in values(all_nodes(geno)))
    swappable = setdiff(all_node_ids, lineage_ids)
    if length(swappable) == 0
        return deepcopy(geno)
    end
    # Select a second node at random from the set of swappable nodes.
    node_id2 = rand(rng, swappable)
    swap_node(geno, node1.id, node_id2)
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
    splice_function(rng::AbstractRNG, gene_id_counter::Counter, ::GeneticProgramMutator, geno::GeneticProgramGenotype)

Randomly splice a function node's subtree into another part of the genotype tree.

# Arguments:
- `rng::AbstractRNG`: Random number generator.
- `gene_id_counter::Counter`: Counter for unique gene IDs.
- `::GeneticProgramMutator`: Mutator operations for genetic programming.
- `geno::GeneticProgramGenotype`: Genotype to splice function into.

# Returns:
- A new `GeneticProgramGenotype` with the spliced function subtree.
"""
function splice_function(
    rng::AbstractRNG, 
    ::Counter,
    geno::GeneticProgramGenotype,
    functions::Dict{FuncAlias, Int},
    terminals::Dict{Terminal, Int},
    ::Float64,
)
    # select a function node at random for splicer_top_id
    if length(geno.functions) == 0
        return deepcopy(geno)
    end
    splicer_top = rand(rng, collect(values(geno.functions)))

    
    # Get all descendents of splicer_top_id for potential splicer_tail_id
    descendents = get_descendents(geno, splicer_top.id)
    splicer_tail = rand(rng, descendents)

    # Identify all nodes not in the lineage of splicer_top and splicer_tail for splicee_id
    lineage_nodes = [get_ancestors(geno, splicer_top.id); splicer_top; descendents]
    lineage_ids = Set(n.id for n in lineage_nodes)
    all_node_ids = Set(n.id for n in values(all_nodes(geno)))
    spliceable = setdiff(all_node_ids, lineage_ids)
    
    # If there are no spliceable nodes, return original genotype
    if isempty(spliceable)
        return deepcopy(geno)
    end

    splicee_id = rand(rng, spliceable)
    
    return splice_function(geno, splicer_top.id, splicer_tail.id, splicee_id)
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
"""
    inject_noise(rng::AbstractRNG, gene_id_counter::Counter, m::GeneticProgramMutator, geno::GeneticProgramGenotype)

Inject noise into a copy of the genotype for each real-valued terminal, using the `noise_std` field from the `GeneticProgramMutator`.

# Arguments:
- `rng::AbstractRNG`: Random number generator.
- `gene_id_counter::Counter`: Counter for unique gene IDs.
- `m::GeneticProgramMutator`: Mutator containing the noise standard deviation.
- `geno::GeneticProgramGenotype`: Genotype to inject noise into.

# Returns:
- A new `GeneticProgramGenotype` with noise injected into real-valued terminals.
"""
function inject_noise(
    rng::AbstractRNG, 
    ::Counter, 
    geno::GeneticProgramGenotype,
    functions::Dict{FuncAlias, Int},
    terminals::Dict{Terminal, Int},
    noise_std::Float64,
)
    noisedict = Dict{Int, Float64}()
    injectable_ids = [id for (id, node) in geno.terminals if isa(node.val, Float64)]
    noisevec = randn(rng, length(injectable_ids)) * noise_std
    noisedict = Dict(zip(injectable_ids, noisevec))
    inject_noise(geno, noisedict)
end

Base.@kwdef struct GeneticProgramMutator <: Mutator
    # Number of structural changes to perform per generation
    n_mutations::Int = 1
    # Uniform probability of each type of structural change
    mutation_probabilities::Dict{Function, Float64} = Dict(
        "add_function" => 1 / 8,
        "remove_function" => 1 / 8,
        "splice_function" => 1 / 8,
        "swap_node" => 1 / 8,
        "identity" => 2 / 4
    )
    terminals::Dict{Terminal, Int} = Dict(
        :read => 1, 
        0.0 => 1, 
    )
    functions::Dict{FuncAlias, Int} = Dict([
        (protected_sine, 1), 
        (protected_cosine, 1), 
        (protected_division, 2), 
        (+, 2), 
        (-, 2), 
        (*, 2),
        (if_less_then_else, 4),
    ])
    noise_std::Float64 = 0.05
    string_arg_dict::Dict{String, Any} = Dict(
        "read" => :read, 
        "+" => +, 
        "-" => -, 
        "*" => *, 
        "protected_sine" => protected_sine, 
        "if_less_then_else" => if_less_then_else)
end


function mutate(
    mutator::GeneticProgramMutator,
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    geno::GeneticProgramGenotype
) 
    mutations = sample(
        rng, 
        collect(keys(mutator.mutation_probabilities)), 
        Weights(collect(values(mutator.mutation_probabilities))), 
        mutator.n_mutations
    )
    for mutation in mutations
        geno = mutation(
            rng, gene_id_counter, geno, mutator.functions, mutator.terminals, mutator.noise_std
        )
    end
    if geno.root_id ∉ keys(all_nodes(geno))
        throw(ErrorException("Root node not in genotype"))
    end
    geno = inject_noise(
        rng, gene_id_counter, geno, mutator.functions, mutator.terminals, mutator.noise_std
    )
    if geno.root_id ∉ keys(all_nodes(geno))
        throw(ErrorException("Root node not in genotype after noise"))
    end
    return geno
end

end