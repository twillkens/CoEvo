
export ExpressionNodeGene, get_child_index

using .....CoEvo.Abstract: Gene

mutable struct ExpressionNodeGene <: Gene
    id::Int
    parent_id::Union{Int, Nothing}
    val::Union{Symbol, Function, Real}
    child_ids::Vector{Int}
end

# Used for constructing terminals
function ExpressionNodeGene(
    id::Int,
    parent::Union{Int, Nothing},
    val::Union{Symbol, Function, Real},
)
    ExpressionNodeGene(id, parent, val, ExpressionNodeGene[])
end

function Base.:(==)(a::ExpressionNodeGene, b::ExpressionNodeGene)
    return a.id == b.id &&
           a.parent_id == b.parent_id &&
           a.val == b.val &&
           a.child_ids == b.child_ids
end

function Base.show(io::IO, enode::ExpressionNodeGene)
    if length(enode.child_ids) == 0
        children = ""
    else
        children = join([child_id for child_id in enode.child_ids], ", ")
        children = "($children)"
    end
    print(io, "$(enode.parent_id) <= $(enode.id) => $(enode.val)$children")
end
