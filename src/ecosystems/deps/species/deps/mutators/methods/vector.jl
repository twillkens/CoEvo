using Random: AbstractRNG

using .....Ecosystems.Utilities.Counters: Counter
using ..Genotypes.Vectors: BasicVectorGenotype
using .Abstract: Mutator

import .Abstract: mutate

# Implement mutation for `BasicVectorGenotype` by introducing random noise to the genes.
function mutate(
    ::Mutator,
    rng::AbstractRNG, 
    ::Counter, 
    geno::BasicVectorGenotype{R}
) where {R <: Real}
    noise = 0.1 .* randn(rng, R, length(geno.genes))
    genes = geno.genes + noise
    geno = BasicVectorGenotype(genes)
    return geno

end