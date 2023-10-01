module Methods

export create_genotypes

using Random: AbstractRNG
using .....Ecosystems.Utilities.Counters: Counter
using ..Genotypes.Abstract: Genotype, GenotypeCreator

import ..Genotypes.Interfaces: create_genotype


"""
    (creator::GenotypeCreator)(rng::AbstractRNG, gene_id_counter::Counter, n_pop::Int)

Generate an array of genotype instances based on the provided genotype configuration `creator`. 
The function leverages the specified random number generator `rng` and gene ID counter `gene_id_counter` 
for this purpose. The number of genotypes returned is determined by `n_pop`.

# Returns
- An array of genotype instances, each derived from the given configuration.
"""
function create_genotypes(
    geno_creator::GenotypeCreator, 
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    n_pop::Int
)
    genotypes = [create_genotype(geno_creator, rng, gene_id_counter) for _ in 1:n_pop]

    return genotypes
end

end