
# Generate a random function node along with its terminals add it to a new copy of the genotype
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
