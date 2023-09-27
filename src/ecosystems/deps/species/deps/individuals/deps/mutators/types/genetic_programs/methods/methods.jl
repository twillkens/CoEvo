export add_function

using Random: AbstractRNG, rand

using ......Ecosystems.Utilities.Counters: Counter, next!
using ...Genotypes.GeneticPrograms: BasicGeneticProgramGenotype

import ...Genotypes.GeneticPrograms: add_function, remove_function, inject_noise, swap_node, splice_function


"""
    add_function(rng::AbstractRNG, gene_id_counter::Counter, mutator::BasicGeneticProgramMutator, geno::BasicGeneticProgramGenotype)

Generate a random function node along with its associated terminals, and add them to a new copy 
of the genotype.

# Arguments:
- `rng::AbstractRNG`: Random number generator.
- `gene_id_counter::Counter`: Counter for unique gene IDs.
- `mutator::BasicGeneticProgramMutator`: The mutator containing function and terminal sets.
- `geno::BasicGeneticProgramGenotype`: The genotype tree to be modified.

# Returns:
- A modified `BasicGeneticProgramGenotype` with the new function node added.
"""
function add_function(
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    mutator::BasicGeneticProgramMutator, 
    geno::BasicGeneticProgramGenotype
)
    newnode_id = next!(gene_id_counter) # Increment spawn counter to find unique gene id
    newnode_val, n_arguments = rand(rng, mutator.functions) # Choose a random function and number of args
    new_child_ids = next!(gene_id_counter, n_arguments)
    new_child_vals = Terminal[rand(rng, keys(mutator.terminals)) for _ in 1:n_arguments] # Choose random terminals
    # The new node is added to the genotype without a parent
    add_function(geno, newnode_id, newnode_val, new_child_ids, new_child_vals)
end

"""
    remove_function(rng::AbstractRNG, ::Counter, ::BasicGeneticProgramMutator, geno::BasicGeneticProgramGenotype)

Randomly select and remove a function node from the genotype. If the genotype has no function nodes, a copy of the original genotype is returned.

# Arguments:
- `rng::AbstractRNG`: Random number generator.
- `::Counter`: Counter for unique gene IDs.
- `::BasicGeneticProgramMutator`: Mutator operations for genetic programming.
- `geno::BasicGeneticProgramGenotype`: Genotype to remove function from.

# Returns:
- A new `BasicGeneticProgramGenotype` with the selected function node removed.
"""
function remove_function(
    rng::AbstractRNG, 
    ::Counter, 
    ::BasicGeneticProgramMutator, 
    geno::BasicGeneticProgramGenotype
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
"""
    swap_node(rng::AbstractRNG, ::Counter, ::BasicGeneticProgramMutator, geno::BasicGeneticProgramGenotype)

Swap two randomly selected nodes in the genotype tree. Nodes that belong to the same lineage (one is an ancestor of the other) cannot be swapped.

# Arguments:
- `rng::AbstractRNG`: Random number generator.
- `::Counter`: Counter for unique gene IDs.
- `::BasicGeneticProgramMutator`: Mutator operations for genetic programming.
- `geno::BasicGeneticProgramGenotype`: Genotype to swap nodes in.

# Returns:
- A new `BasicGeneticProgramGenotype` with the specified nodes swapped.
"""
function swap_node(
    rng::AbstractRNG, 
    ::Counter, 
    ::BasicGeneticProgramMutator, 
    geno::BasicGeneticProgramGenotype
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
    inject_noise(rng::AbstractRNG, gene_id_counter::Counter, m::BasicGeneticProgramMutator, geno::BasicGeneticProgramGenotype)

Inject noise into a copy of the genotype for each real-valued terminal, using the `noise_std` field from the `BasicGeneticProgramMutator`.

# Arguments:
- `rng::AbstractRNG`: Random number generator.
- `gene_id_counter::Counter`: Counter for unique gene IDs.
- `m::BasicGeneticProgramMutator`: Mutator containing the noise standard deviation.
- `geno::BasicGeneticProgramGenotype`: Genotype to inject noise into.

# Returns:
- A new `BasicGeneticProgramGenotype` with noise injected into real-valued terminals.
"""
function inject_noise(
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    m::BasicGeneticProgramMutator, 
    geno::BasicGeneticProgramGenotype
)
    noisedict = Dict{Int, Float64}()
    injectable_ids = [id for (id, node) in geno.terminals if isa(node.val, Float64)]
    noisevec = randn(rng, length(injectable_ids)) * m.noise_std
    noisedict = Dict(zip(injectable_ids, noisevec))
    inject_noise(geno, noisedict)
end