
module NoiseInjection

export NoiseInjectionMutator

using ...Mutators.Abstract: Mutator
using Random: AbstractRNG
using .....Ecosystems.Utilities.Counters: Counter
using  ....Species.Genotypes.Vectors.Basic: BasicVectorGenotype

import ...Mutators.Interfaces: mutate

Base.@kwdef struct NoiseInjectionMutator <: Mutator 
    noise_std::Float64 = 0.1
end

function mutate(
    mutator::NoiseInjectionMutator, 
    rng::AbstractRNG, 
    ::Counter,
    geno::BasicVectorGenotype
)
    # Inject noise into the genotype's genes
    noise = randn(rng, length(geno.genes)) .* mutator.noise_std
    new_genes = geno.genes .+ noise
    genotype = BasicVectorGenotype(new_genes)
    return genotype
end
"""
    DefaultMutator

A default mutator structure used in the co-evolutionary ecosystem. This basic mutator 
can be extended or replaced with more specific mutation behaviors in derived modules.
"""

end