export BasicGeneticProgramGenotypeCreator

using ......Ecosystems.Utilities.Counters: Counter
using ..Abstract: GeneticProgramGenotypeCreator, AbstractRNG

import ...Interfaces: create_genotype   


"""
    BasicGeneticProgramGenotypeCreator <: GeneticProgramGenotypeCreator 

Creator for creating a `BasicGeneticProgramGenotype`.

# Fields:
- `startval::Union{Symbol, Function, Real}`: Initial value to be used for the terminal node. Default is `0.0`.
"""
Base.@kwdef struct BasicGeneticProgramGenotypeCreator <: GeneticProgramGenotypeCreator 
    startval::Union{Symbol, Function, Real} = 0.0
end

"""
    (geno_creator::BasicGeneticProgramGenotypeCreator)(rng::AbstractRNG, gene_id_counter::Counter) -> BasicGeneticProgramGenotype

Construct a `BasicGeneticProgramGenotype` using the provided configuration.

# Arguments
- `rng::AbstractRNG`: Random number generator.
- `gene_id_counter::Counter`: Counter for generating unique gene IDs.

# Returns
- `BasicGeneticProgramGenotype`: A new genotype instance.
"""
function create_genotype(
    geno_creator::BasicGeneticProgramGenotypeCreator,
    ::AbstractRNG, 
    gene_id_counter::Counter
)
    root_id = next!(gene_id_counter)
    BasicGeneticProgramGenotype(
        root_id = root_id,
        terminals = Dict(
            root_id => ExpressionNodeGene(root_id, nothing, geno_creator.startval)
        )
    )
end