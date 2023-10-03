module Creators

export GeneticProgramGenotypeCreator

using .....Ecosystems.Utilities.Counters: Counter, next!
using Random: AbstractRNG
using ..GeneticPrograms.Genes: ExpressionNodeGene
using ..GeneticPrograms.Genotypes: GeneticProgramGenotype
using ...Genotypes.Abstract: GenotypeCreator

import ...Genotypes.Interfaces: create_genotypes   

"""
    GeneticProgramGenotypeCreator <: GeneticProgramGenotypeCreator 

Creator for creating a `GeneticProgramGenotype`.

# Fields:
- `startval::Union{Symbol, Function, Real}`: Initial value to be used for the terminal node. Default is `0.0`.
"""
Base.@kwdef struct GeneticProgramGenotypeCreator <: GenotypeCreator 
    startval::Union{Symbol, Function, Real} = 0.0
end

"""
    (geno_creator::GeneticProgramGenotypeCreator)(rng::AbstractRNG, gene_id_counter::Counter) -> GeneticProgramGenotype

Construct a `GeneticProgramGenotype` using the provided configuration.

# Arguments
- `rng::AbstractRNG`: Random number generator.
- `gene_id_counter::Counter`: Counter for generating unique gene IDs.

# Returns
- `GeneticProgramGenotype`: A new genotype instance.
"""
function create_genotype(
    geno_creator::GeneticProgramGenotypeCreator,
    gene_id_counter::Counter
)
    root_id = next!(gene_id_counter)
    GeneticProgramGenotype(
        root_id = root_id,
        terminals = Dict(
            root_id => ExpressionNodeGene(root_id, nothing, geno_creator.startval)
        )
    )
end

function create_genotypes(
    geno_creator::GeneticProgramGenotypeCreator,
    ::AbstractRNG,
    gene_id_counter::Counter,
    n_pop::Int
)
    genotypes = [create_genotype(geno_creator, gene_id_counter) for _ in 1:n_pop]
    return genotypes
end

end