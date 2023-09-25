"""
    Abstract

This module contains abstract definitions related to genotype configurations in the co-evolutionary ecosystem.
It provides foundational behaviors for genotype configurations, which can be extended in derived modules.
"""
module Abstract

using Random: AbstractRNG
using .....CoEvo.Abstract: GenotypeConfiguration
using .....CoEvo.Utilities.Counters: Counter

"""
    (geno_cfg::GenotypeConfiguration)(rng::AbstractRNG, counter::Counter)

Attempt to generate a genotype instance based on the provided genotype configuration `geno_cfg`, 
utilizing the given random number generator `rng` and gene ID counter `counter`.

# Exceptions
- Raises an `ErrorException` if the specific genotype configuration hasn't been implemented.
"""
function(geno_cfg::GenotypeConfiguration)(rng::AbstractRNG, counter::Counter)
    throw(ErrorException("Genotype configuration not implemented."))
end

"""
    (cfg::GenotypeConfiguration)(rng::AbstractRNG, gene_id_counter::Counter, n_pop::Int)

Generate an array of genotype instances based on the provided genotype configuration `cfg`. 
The function leverages the specified random number generator `rng` and gene ID counter `gene_id_counter` 
for this purpose. The number of genotypes returned is determined by `n_pop`.

# Returns
- An array of genotype instances, each derived from the given configuration.
"""
function(geno_cfg::GenotypeConfiguration)(
    rng::AbstractRNG, gene_id_counter::Counter, n_pop::Int
)
    [geno_cfg(rng, gene_id_counter) for _ in 1:n_pop]
end

end
