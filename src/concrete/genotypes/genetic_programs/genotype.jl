export ExpressionNode, GeneticProgramGenotype, GeneticProgramGenotypeCreator

import ....Interfaces: create_genotypes   

using ....Abstract: Genotype, GenotypeCreator, AbstractRNG, Counter
using ....Interfaces: step!
"""
    ExpressionNode

Represents a node within the expression tree of the genetic program genotype.

# Fields:
- `id::Int`: Unique identifier for the node.
- `parent_id::Union{Int, Nothing}`: Identifier for the parent node. `Nothing` for root node.
- `val::Union{Symbol, Function, Real}`: Value contained in the node. It can be a function, a symbol or a real number.
- `child_ids::Vector{Int}`: List of identifiers for child nodes.
"""
mutable struct ExpressionNode
    id::Int
    parent_id::Union{Int, Nothing}
    val::Union{Symbol, Function, Real}
    child_ids::Vector{Int}
end

function ExpressionNode(
    id::Int, parent::Union{Int, Nothing}, val::Union{Symbol, Function, Real}
)
    ExpressionNode(id, parent, val, Int[])
end

function Base.:(==)(a::ExpressionNode, b::ExpressionNode)
    return a.id == b.id &&
           a.parent_id == b.parent_id &&
           a.val == b.val &&
           a.child_ids == b.child_ids
end

function Base.show(io::IO, enode::ExpressionNode)
    if length(enode.child_ids) == 0
        children = ""
    else
        children = join([child_id for child_id in enode.child_ids], ", ")
        children = "($children)"
    end
    print(io, "$(enode.parent_id) <= $(enode.id) => $(enode.val)$children")
end

"""
    GeneticProgramGenotype

Represents the genetic program's genotype structure.

# Fields:
- `root_id::Int`: Identifier for the root node.
- `functions::Dict{Int, ExpressionNode}`: Dictionary mapping node IDs to function nodes.
- `terminals::Dict{Int, ExpressionNode}`: Dictionary mapping node IDs to terminal nodes (leaves).
"""
Base.@kwdef mutable struct GeneticProgramGenotype <: Genotype
    root_id::Int = 1
    functions::Dict{Int, ExpressionNode} = Dict{Int, ExpressionNode}()
    terminals::Dict{Int, ExpressionNode} = Dict{Int, ExpressionNode}()
end

function Base.show(io::IO, geno::GeneticProgramGenotype)
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

function Base.:(==)(a::GeneticProgramGenotype, b::GeneticProgramGenotype)
    return a.root_id == b.root_id &&
           a.functions == b.functions &&
           a.terminals == b.terminals
end

"""
    GeneticProgramGenotypeCreator

Utility structure to aid in the creation of `GeneticProgramGenotype` instances.

# Fields:
- `default_terminal_value::Union{Symbol, Function, Real}`: Default value for terminal nodes during genotype creation.
"""
Base.@kwdef struct GeneticProgramGenotypeCreator <: GenotypeCreator 
    default_terminal_value::Union{Symbol, Function, Real} = 0.0
end

"""
    create_genotype(geno_creator::GeneticProgramGenotypeCreator, gene_id_counter::Counter)

Generate a new `GeneticProgramGenotype` instance with a single terminal node using the default value.
"""
function create_genotype(
    geno_creator::GeneticProgramGenotypeCreator,
    gene_id_counter::Counter
)
    root_id = step!(gene_id_counter)
    genotype = GeneticProgramGenotype(
        root_id = root_id,
        terminals = Dict(
            root_id => ExpressionNode(
                root_id, nothing, geno_creator.default_terminal_value
            )
        )
    )
    return genotype
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