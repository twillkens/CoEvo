export BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeCreator

using Random: AbstractRNG

using ......Ecosystems.Utilities.Counters: Counter, next!

"""
    ExpressionNodeGene

A data structure representing a node within the expression tree of a genetic program. Each node 
can either be a terminal (e.g., a real value, a variable) or an operator (function) which may 
have child nodes.

# Fields:
- `id::Int`: Unique identifier for the node.
- `parent_id::Union{Int, Nothing}`: ID of the parent node. `Nothing` if it's a root node.
- `val::Union{Symbol, Function, Real}`: The value or operation associated with the node.
- `child_ids::Vector{Int}`: A list of IDs corresponding to the child nodes.
"""
mutable struct ExpressionNodeGene
    id::Int
    parent_id::Union{Int, Nothing}
    val::Union{Symbol, Function, Real}
    child_ids::Vector{Int}
end

"""
    ExpressionNodeGene(id::Int, parent::Union{Int, Nothing}, val::Union{Symbol, Function, Real})

Constructor for creating terminal `ExpressionNodeGene` nodes. Terminals are nodes that do not 
    have child nodes.

# Arguments:
- `id::Int`: Unique identifier for the node.
- `parent::Union{Int, Nothing}`: ID of the parent node. `Nothing` if it's a root node.
- `val::Union{Symbol, Function, Real}`: The value associated with the terminal node.

# Returns:
- A new terminal `ExpressionNodeGene` instance.
"""
function ExpressionNodeGene(
    id::Int, parent::Union{Int, Nothing}, val::Union{Symbol, Function, Real}
)
    ExpressionNodeGene(id, parent, val, ExpressionNodeGene[])
end

"""
    Base.:(==)(a::ExpressionNodeGene, b::ExpressionNodeGene)

Overload of the equality operator for `ExpressionNodeGene`. Two nodes are considered equal if 
their fields are the same.

# Arguments:
- `a::ExpressionNodeGene`: First node.
- `b::ExpressionNodeGene`: Second node.

# Returns:
- `true` if nodes are equal, otherwise `false`.
"""
function Base.:(==)(a::ExpressionNodeGene, b::ExpressionNodeGene)
    return a.id == b.id &&
           a.parent_id == b.parent_id &&
           a.val == b.val &&
           a.child_ids == b.child_ids
end

"""
    Base.show(io::IO, enode::ExpressionNodeGene)

Custom display method for `ExpressionNodeGene` when printed.

# Arguments:
- `io::IO`: Output stream.
- `enode::ExpressionNodeGene`: Node to be displayed.

# Output:
- A formatted string showing the parent, the node ID, the value, and its children (if any).
"""
function Base.show(io::IO, enode::ExpressionNodeGene)
    if length(enode.child_ids) == 0
        children = ""
    else
        children = join([child_id for child_id in enode.child_ids], ", ")
        children = "($children)"
    end
    print(io, "$(enode.parent_id) <= $(enode.id) => $(enode.val)$children")
end

"""
    BasicGeneticProgramGenotype <: GeneticProgramGenotype

A simple genetic program genotype representation.

# Fields:
- `root_id::Int`: The ID of the root node.
- `functions::Dict{Int, ExpressionNodeGene}`: A dictionary of function nodes keyed by their unique identifiers.
- `terminals::Dict{Int, ExpressionNodeGene}`: A dictionary of terminal nodes keyed by their unique identifiers.
"""
Base.@kwdef mutable struct BasicGeneticProgramGenotype <: GeneticProgramGenotype
    root_id::Int = 1
    functions::Dict{Int, ExpressionNodeGene} = Dict{Int, ExpressionNodeGene}()
    terminals::Dict{Int, ExpressionNodeGene} = Dict{Int, ExpressionNodeGene}()
end

"""
    ==(a::BasicGeneticProgramGenotype, b::BasicGeneticProgramGenotype) -> Bool

Compare two `BasicGeneticProgramGenotype` instances for equality.

# Arguments
- `a::BasicGeneticProgramGenotype`: First genotype to compare.
- `b::BasicGeneticProgramGenotype`: Second genotype to compare.

# Returns
- `Bool`: `true` if the genotypes are equal, otherwise `false`.
"""
function Base.:(==)(a::BasicGeneticProgramGenotype, b::BasicGeneticProgramGenotype)
    return a.root_id == b.root_id &&
           a.functions == b.functions &&
           a.terminals == b.terminals
end

"""
    show(io::IO, geno::BasicGeneticProgramGenotype)

Display a textual representation of the `BasicGeneticProgramGenotype` to the provided IO stream.

# Arguments
- `io::IO`: The IO stream to write to.
- `geno::BasicGeneticProgramGenotype`: The genotype instance to display.
"""
function Base.show(io::IO, geno::BasicGeneticProgramGenotype)
    print(io, "BasicGeneticProgramGenotype(\n")
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
