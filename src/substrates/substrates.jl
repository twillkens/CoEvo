"""
    Substrates

Module providing substrate configurations and utilities, primarily for genotypes.
"""
module Substrates

export VectorGenoCfg, RandVectorGenoCfg

using Random
using ...CoEvo: GenotypeConfiguration
using ...CoEvo.Utilities: Counter

# Including vector-based genotype configurations
include("vector/vector.jl")

# Importing defined genotype configurations from the included vector module
using .VectorSubstrate: VectorGenoCfg, RandVectorGenoCfg
export VectorGenoCfg, RandVectorGenoCfg  # Exporting for external use

"""
    (cfg::GenotypeConfiguration)(rng::AbstractRNG, counter::Counter)

Generate a `VectorGeno` instance from the provided genotype configuration, `cfg`, 
using the given random number generator, `rng`, and counter, `counter`.
"""
function(cfg::GenotypeConfiguration)(rng::AbstractRNG, counter::Counter)
    VectorGeno(cfg(rng, counter))
end

"""
    (cfg::GenotypeConfiguration)(rng::AbstractRNG, gene_id_counter::Counter, n_pop::Int)

Generate an array of genotype instances from the provided genotype configuration, `cfg`,
using the specified random number generator, `rng`, and gene ID counter, `gene_id_counter`.
The length of the returned array is determined by `n_pop`.
"""
function(cfg::GenotypeConfiguration)(rng::AbstractRNG, gene_id_counter::Counter, n_pop::Int)
    [cfg(rng, gene_id_counter) for _ in 1:n_pop]
end

end
