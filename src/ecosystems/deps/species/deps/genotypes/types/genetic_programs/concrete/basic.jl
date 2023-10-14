module Basic

export BasicExpressionNodeGene, BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeCreator

using Random: AbstractRNG
using ......Ecosystems.Utilities.Counters: Counter, next!
using ...GeneticPrograms.Abstract: GeneticProgramGenotype, ExpressionNodeGene
using ...GeneticPrograms.Abstract: GeneticProgramGenotypeCreator

import ....Genotypes.Interfaces: create_genotypes   

mutable struct BasicExpressionNodeGene
    id::Int
    parent_id::Union{Int, Nothing}
    val::Union{Symbol, Function, Real}
    child_ids::Vector{Int}
end

function BasicExpressionNodeGene(
    id::Int, parent::Union{Int, Nothing}, val::Union{Symbol, Function, Real}
)
    BasicExpressionNodeGene(id, parent, val, Int[])
end

function Base.:(==)(a::BasicExpressionNodeGene, b::BasicExpressionNodeGene)
    return a.id == b.id &&
           a.parent_id == b.parent_id &&
           a.val == b.val &&
           a.child_ids == b.child_ids
end

function Base.show(io::IO, enode::BasicExpressionNodeGene)
    if length(enode.child_ids) == 0
        children = ""
    else
        children = join([child_id for child_id in enode.child_ids], ", ")
        children = "($children)"
    end
    print(io, "$(enode.parent_id) <= $(enode.id) => $(enode.val)$children")
end
# Fields:
"""
- `root_id::Int`: The ID of the root node.
- `functions::Dict{Int, ExpressionNodeGene}`: A dictionary of function nodes keyed by their unique identifiers.
- `terminals::Dict{Int, ExpressionNodeGene}`: A dictionary of terminal nodes keyed by their unique identifiers.
"""
Base.@kwdef mutable struct BasicGeneticProgramGenotype <: GeneticProgramGenotype
    root_id::Int = 1
    functions::Dict{Int, BasicExpressionNodeGene} = Dict{Int, BasicExpressionNodeGene}()
    terminals::Dict{Int, BasicExpressionNodeGene} = Dict{Int, BasicExpressionNodeGene}()
end

"""
    show(io::IO, geno::GeneticProgramGenotype)

Display a textual representation of the `GeneticProgramGenotype` to the provided IO stream.

# Arguments
- `io::IO`: The IO stream to write to.
- `geno::GeneticProgramGenotype`: The genotype instance to display.
"""
function Base.show(io::IO, geno::BasicGeneticProgramGenotype)
    print(io, "GeneticProgramGenotype(\n")
    print(io, "    root_id = $(geno.root_id),\n")
    print(io, "    functions = Dict(\n")
    for (id, node) in geno.functions
        print(io, "        $node,\n")
    end
    print(io, "    ),\n")
    print(io, "    terminals = Dict(\n")
    for (id, node) in geno.terminals
        print(io, "        $node,\n")
    end
    print(io, "    ),\n")
    print(io, ")")
end

Base.@kwdef struct BasicGeneticProgramGenotypeCreator <: GeneticProgramGenotypeCreator 
    default_terminal_value::Union{Symbol, Function, Real} = 0.0
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
    geno_creator::BasicGeneticProgramGenotypeCreator,
    gene_id_counter::Counter
)
    root_id = next!(gene_id_counter)
    genotype = BasicGeneticProgramGenotype(
        root_id = root_id,
        terminals = Dict(
            root_id => BasicExpressionNodeGene(
                root_id, nothing, geno_creator.default_terminal_value
            )
        )
    )
    return genotype
end

function create_genotypes(
    geno_creator::BasicGeneticProgramGenotypeCreator,
    ::AbstractRNG,
    gene_id_counter::Counter,
    n_pop::Int
)
    genotypes = [create_genotype(geno_creator, gene_id_counter) for _ in 1:n_pop]
    return genotypes
end


end