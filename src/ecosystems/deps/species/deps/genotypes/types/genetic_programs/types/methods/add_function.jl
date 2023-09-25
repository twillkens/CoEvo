export add_function

# Make a copy of the genotype and create the new function node and its terminals
# before adding to the genotype func and term dicts.
# By default a new function and its terminals are disconnected from the rest of the 
# genotype and execution tree. It may be added later through a swap operation
function add_function(
    geno::BasicGeneticProgramGenotype, 
    newnode_gid::Real, 
    newnode_val::Union{FuncAlias},
    newnode_child_gids::Vector{<:Real},
    newnode_child_vals::Vector{<:Terminal},
)
    geno = deepcopy(geno)
    new_child_nodes = [
        ExpressionNodeGene(
            newnode_child_gids[i], 
            newnode_gid, 
            newnode_child_vals[i], 
            ExpressionNodeGene[]
        ) 
        for i in 1:length(newnode_child_gids)
    ]
    new_node = ExpressionNodeGene(newnode_gid, nothing, newnode_val, newnode_child_gids)
    push!(geno.funcs, new_node.gid => new_node)
    [push!(geno.terms, child.gid => child) for child in new_child_nodes]
    geno
end

# Generate a random function node along with its terminals add it to a new copy of the genotype
function add_function(rng::AbstractRNG, sc::SpawnCounter, m::BasicGeneticProgramMutator, geno::BasicGeneticProgramGenotype)
    newnode_gid = gid!(sc) # Increment spawn counter to find unique gene id
    newnode_val, ndim = rand(rng, m.functions) # Choose a random function and number of args
    new_child_gids = [gid!(sc) for _ in 1:ndim] # Generate unique gene ids for the children
    new_child_vals = Terminal[rand(rng, keys(m.terminals)) for _ in 1:ndim] # Choose random terminals
    # The new node is added to the genotype without a parent
    add_function(geno, newnode_gid, newnode_val, new_child_gids, new_child_vals)
end
