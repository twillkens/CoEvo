export ExprNode, GPGeno, GPIndiv, GPIndivCfg
# Gene element of a GPGeno
mutable struct ExprNode <: Gene
    gid::Int
    parent_gid::Union{Int, Nothing}
    val::Union{Symbol, Function, Real}
    child_gids::Vector{Int}
end

# Used for constructing terminals
function ExprNode(
    gid::Int,
    parent::Union{Int, Nothing},
    val::Union{Symbol, Function, Real},
)
    ExprNode(gid, parent, val, ExprNode[])
end

function Base.:(==)(a::ExprNode, b::ExprNode)
    return a.gid == b.gid &&
           a.parent_gid == b.parent_gid &&
           a.val == b.val &&
           a.child_gids == b.child_gids
end

function Base.show(io::IO, enode::ExprNode)
    if length(enode.child_gids) == 0
        children = ""
    else
        children = join([child_gid for child_gid in enode.child_gids], ", ")
        children = "($children)"
    end
    print(io, "$(enode.parent_gid) <= $(enode.gid) => $(enode.val)$children")
end

# Basic genotype for GP individuals
Base.@kwdef mutable struct GPGeno <: Genotype
    root_gid::Int = 1
    funcs::Dict{Int, ExprNode} = Dict{Int, ExprNode}()
    terms::Dict{Int, ExprNode} = Dict{Int, ExprNode}()
end

function Base.:(==)(a::GPGeno, b::GPGeno)
    return a.root_gid == b.root_gid &&
           a.funcs == b.funcs &&
           a.terms == b.terms
end

function Base.show(io::IO, geno::GPGeno)
    print(io, "GPGeno(\n")
    print(io, "    root_gid = $(geno.root_gid),\n")
    print(io, "    funcs = Dict(\n")
    for (gid, node) in geno.funcs
        print(io, "        $node,\n")
    end
    print(io, "    ),\n")
    print(io, "    terms = Dict(\n")
    for (gid, node) in geno.terms
        print(io, "        $node,\n")
    end
    print(io, "    ),\n")
    print(io, ")")
end

# Get all nodes in the genotype as a dictionary
function all_nodes(geno::GPGeno)
    merge(geno.funcs, geno.terms)
end

# Get selected nodes from the genotype as a vector
function get_nodes(geno::GPGeno, gids::Vector{Int})
    all_nodes = merge(geno.funcs, geno.terms)
    [haskey(all_nodes, gid) ? all_nodes[gid] : nothing for gid in gids]
end

# Get specific node from the genotype
function get_node(geno::GPGeno, gid::Union{Int, Nothing})
    if gid === nothing
        return nothing
    end
    all_nodes = merge(geno.funcs, geno.terms)
    haskey(all_nodes, gid) ? all_nodes[gid] : nothing
end

function get_root(geno::GPGeno)
    get_node(geno, geno.root_gid)
end

# Get parent node of a node in the genotype
function get_parent_node(geno::GPGeno, node::ExprNode)
    if node.parent_gid === nothing
        return nothing
    end
    return get_node(geno, node.parent_gid)
end

# Get children nodes of a node in the genotype
function get_child_nodes(geno::GPGeno, node::ExprNode)
    if length(node.child_gids) == 0
        return ExprNode[]
    end
    get_nodes(geno, node.child_gids)
end

# Recursively gather all parent nodes of a node in the genotype
function get_ancestors(geno::GPGeno, root::ExprNode)
    if root.parent_gid === nothing
        return ExprNode[]
    end
    parent_node = get_parent_node(geno, root)
    [parent_node, get_ancestors(geno, parent_node)...]
end

# Recursivly gather al child, grandchild, etc, nodes of a node in the genotype
function get_descendents(geno::GPGeno, root::ExprNode)
    if length(root.child_gids) == 0
        return ExprNode[]
    end
    nodes = ExprNode[]
    for child_node in get_child_nodes(geno, root)
        push!(nodes, child_node)
        append!(nodes, get_descendents(geno, child_node))
    end
    nodes
end

function get_descendents(geno::GPGeno, root_gid::Int)
    get_descendents(geno, get_node(geno, root_gid))
end

function get_ancestors(geno::GPGeno, root_gid::Int)
    get_ancestors(geno, get_node(geno, root_gid))
end


Base.@kwdef struct GPGenoCfg <: GenoConfig 
    startval::Union{Symbol, Function, Real} = 0.0
end

function(geno_cfg::GPGenoCfg)(sc::SpawnCounter)
    root_gid = gid!(sc)
    GPGeno(
        root_gid = root_gid,
        terms = Dict(root_gid => ExprNode(root_gid, nothing, geno_cfg.startval)),
    )
end

function(geno_cfg::GPGenoCfg)(::AbstractRNG, sc::SpawnCounter, n_pop::Int)
    [geno_cfg(sc) for _ in 1:n_pop]
end