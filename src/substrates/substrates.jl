module Substrates

export VectorGenoCfg, RandVectorGenoCfg

using Random
using ...CoEvo: GenotypeConfiguration
using ...CoEvo.Utilities: Counter

include("vector/vector.jl")

using .VectorSubstrate: VectorGenoCfg, RandVectorGenoCfg
export VectorGenoCfg, RandVectorGenoCfg

function(cfg::GenotypeConfiguration)(rng::AbstractRNG, counter::Counter)
    VectorGeno(cfg(rng, counter))
end

function(cfg::GenotypeConfiguration)(rng::AbstractRNG, gene_id_counter::Counter, n_pop::Int)
    [cfg(rng, gene_id_counter) for _ in 1:n_pop]
end

end