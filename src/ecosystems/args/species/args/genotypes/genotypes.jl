"""
    Substrates

Module providing substrate configurations and utilities, primarily for genotypes.
"""
module Genotypes

export VectorGeno, VectorGenoCfg, RandVectorGenoCfg

using Random
using ....CoEvo: GenotypeConfiguration
using ..Utilities: Counter

# Including vector-based genotype configurations
include("types/vector/vector.jl")

# Importing defined genotype configurations from the included vector module
using .VectorGenotype: VectorGeno, VectorGenoCfg, RandVectorGenoCfg


function(geno_cfg::GenotypeConfiguration)(rng::AbstractRNG, counter::Counter)
    throw(ErrorException("Genotype configuration not implemented."))
end

"""
    (cfg::GenotypeConfiguration)(rng::AbstractRNG, gene_id_counter::Counter, n_pop::Int)

Generate an array of genotype instances from the provided genotype configuration, `cfg`,
using the specified random number generator, `rng`, and gene ID counter, `gene_id_counter`.
The length of the returned array is determined by `n_pop`.
"""
function(geno_cfg::GenotypeConfiguration)(
    rng::AbstractRNG, gene_id_counter::Counter, n_pop::Int
)
    [geno_cfg(rng, gene_id_counter) for _ in 1:n_pop]
end

end
