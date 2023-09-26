export inject_noise

using Random: AbstractRNG, randn

using ......CoEvo.Utilities.Counters: Counter
using ..Genotypes: BasicGeneticProgramGenotype
using ..Mutators: BasicGeneticProgramMutator

import ..Genotypes.Mutations: inject_noise

"""
    inject_noise(rng::AbstractRNG, gene_id_counter::Counter, m::BasicGeneticProgramMutator, geno::BasicGeneticProgramGenotype)

Inject noise into a copy of the genotype for each real-valued terminal, using the `noise_std` field from the `BasicGeneticProgramMutator`.

# Arguments:
- `rng::AbstractRNG`: Random number generator.
- `gene_id_counter::Counter`: Counter for unique gene IDs.
- `m::BasicGeneticProgramMutator`: Mutator containing the noise standard deviation.
- `geno::BasicGeneticProgramGenotype`: Genotype to inject noise into.

# Returns:
- A new `BasicGeneticProgramGenotype` with noise injected into real-valued terminals.
"""
function inject_noise(
    rng::AbstractRNG, 
    gene_id_counter::Counter, 
    m::BasicGeneticProgramMutator, 
    geno::BasicGeneticProgramGenotype
)
    noisedict = Dict{Int, Float64}()
    injectable_ids = [id for (id, node) in geno.terms if isa(node.val, Float64)]
    noisevec = randn(rng, length(injectable_ids)) * m.noise_std
    noisedict = Dict(zip(injectable_ids, noisevec))
    inject_noise(geno, noisedict)
end