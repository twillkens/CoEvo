module Genes

export ExpressionNodeGene, get_child_index

using ......CoEvo.Abstract: Gene

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
mutable struct ExpressionNodeGene <: Gene
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

end