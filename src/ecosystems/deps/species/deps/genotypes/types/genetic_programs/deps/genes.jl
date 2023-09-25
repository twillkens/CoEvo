
mutable struct ExpressionNodeGene <: Gene
    gid::Int
    parent_gid::Union{Int, Nothing}
    val::Union{Symbol, Function, Real}
    child_gids::Vector{Int}
end

# Used for constructing terminals
function ExpressionNodeGene(
    gid::Int,
    parent::Union{Int, Nothing},
    val::Union{Symbol, Function, Real},
)
    ExpressionNodeGene(gid, parent, val, ExpressionNodeGene[])
end

function Base.:(==)(a::ExpressionNodeGene, b::ExpressionNodeGene)
    return a.gid == b.gid &&
           a.parent_gid == b.parent_gid &&
           a.val == b.val &&
           a.child_gids == b.child_gids
end

function Base.show(io::IO, enode::ExpressionNodeGene)
    if length(enode.child_gids) == 0
        children = ""
    else
        children = join([child_gid for child_gid in enode.child_gids], ", ")
        children = "($children)"
    end
    print(io, "$(enode.parent_gid) <= $(enode.gid) => $(enode.val)$children")
end

function get_child_index(parent_node::ExpressionNodeGene, child_node::ExpressionNodeGene)
    findfirst(x -> x == child_node.gid, parent_node.child_gids)
end