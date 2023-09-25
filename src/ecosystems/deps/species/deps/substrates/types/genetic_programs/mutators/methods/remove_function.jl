export remove_function


# Randomly select a function node and one of its children and remove the function node
# If the genotype has no function nodes, then return a copy of the genotype
function remove_function(
    rng::AbstractRNG, 
    ::Counter, 
    ::BasicGeneticProgramMutator, 
    geno::BasicGeneticProgramGenotype
)
    if length(geno.functions) == 0
        return deepcopy(geno)
    end
    # select a function node at random
    to_remove = rand(rng, geno.functions).second
    # choose node to substitute at random
    to_substitute_id = rand(rng, to_remove.child_ids)
    # execute removal
    remove_function(geno, to_remove.id, to_substitute_id)
end