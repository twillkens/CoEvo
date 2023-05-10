using Random
using StableRNGs
using CoEvo

mutable struct ExprNode
    val::Union{Symbol, Function, Real} 
    parent::Union{ExprNode, Nothing}
    children::Vector{Union{ExprNode, Nothing}}
end

function ExprNode(
    v::Union{Symbol, Function, Real},
)
    ExprNode(v, nothing, ExprNode[])
end

function ExprNode(
    val::Union{Symbol, Function, Real},
    ndim::Int,
)  
    ExprNode(val, nothing, Union{Nothing, ExprNode}[nothing for i in 1:ndim])
end

function ExprNode(
    v::Union{Symbol, Function, Real},
    p::Union{ExprNode, Nothing},
)
    ExprNode(v, p, ExprNode[])
end

function ExprNode(
    expr::Expr, 
    p::Union{ExprNode, Nothing} = nothing
)
    enode = ExprNode(expr.args[1], p, Union{ExprNode, Nothing}[])
    for e in expr.args[2:end]
        push!(enode.children, ExprNode(e, enode))
    end
    enode
end

function Base.Expr(enode::ExprNode)
    if isa(enode.val, Symbol) || isa(enode.val, Real)
        return enode.val
    else
        return Expr(:call, enode.val, Expr.(enode.children)...)
    end
end

mutable struct GPGeno <: Genotype
    root::ExprNode
    nodes::Set{ExprNode}
    funcs::Set{ExprNode}
    terms::Set{ExprNode}
end

mutable struct GPTree
    root::ExprNode
    nodes::Set{ExprNode}
    funcs::Set{ExprNode}
    terms::Set{ExprNode}
end

struct GPIndiv <: Individual
    geno::GPGeno
end



function Base.Expr(geno::GPGeno)
    Expr(geno.root)
end

struct GPPheno <: Phenotype
    ikey::IndivKey
    expr::Expr
end

Base.@kwdef struct GPMutator <: Mutator
    nchanges::Int = 1
    probs::Dict{Function, Float64} = Dict(
        addfunc => 0.1,
        rmfunc => 0.1,
        swapnode => 0.1,
    )
    mut_factor::Float64 = 0.1
    terminals::Dict{Terminal, Int} = Dict([(:read, 1), (0, 1)])
    functions::Dict{FuncAlias, Int} = Dict([(psin, 1), (+, 2)])
end

function addfunc(
    geno::GPGeno, 
    target_node::ExprNode, 
    newfunc::ExprNode, 
    new_children::Vector{ExprNode}
)
    push!(geno.nodes, newfunc)
    push!(geno.funcs, newfunc)
    [push!(geno.terms, c) for c in new_children if c !== target_node]
    newfunc.children = new_children
    newfunc.parent = target_node.parent
    if target_node.parent !== nothing
        idx = findfirst(x -> x == target_node, target_node.parent.children)
        target_node.parent.children[idx] = newfunc
    else
        geno.root = newfunc
    end
    for c in new_children
        c.parent = newfunc
    end
    geno
end

function addfunc(rng::AbstractRNG, m::GPMutator, geno::GPGeno)
    geno = deepcopy(geno)
    target_node = rand(rng, geno.nodes)
    newfunc, ndim = rand(rng, m.functions)
    newnode = ExprNode(newfunc)
    new_children = shuffle(
        rng,
        [[ExprNode(rand(rng, keys(m.terminals))) for _ in 1:ndim - 1]; target_node]
    )
    addfunc(geno, target_node, newnode, new_children)
end

function getleaves(root::ExprNode)
    leaves = ExprNode[]
    for c in root.children
        if length(c.children) == 0
            push!(leaves, c)
        else
            leaves = vcat(leaves, getleaves(c))
        end
    end
    leaves
end

function rmfunc(
    geno::GPGeno,
    target_node::ExprNode, 
    newroot::ExprNode, 
    leafsubs::Vector{Pair{ExprNode, ExprNode}}
)
    delete!(geno.nodes, target_node)
    delete!(geno.funcs, target_node)
    newroot.parent = target_node.parent
    if target_node.parent !== nothing
        idx = findfirst(x -> x == target_node, target_node.parent.children)
        target_node.parent.children[idx] = newroot
    else
        geno.root = newroot
    end
    for (child, leaf) in leafsubs
        child.parent = leaf.parent
        leaf.parent.children[findfirst(x -> x == leaf, leaf.parent.children)] = child
        delete!(geno.terms, leaf)
    end
    geno
end

function rmfunc(rng::AbstractRNG, ::GPMutator, geno::GPGeno)
    if length(geno.funcs) == 1
        return deepcopy(geno)
    end
    geno = deepcopy(geno)
    # select a function node at random
    target_node = rand(rng, geno.funcs)
    # select a child node of the target node at random
    childfuncs = [c for c in target_node.children if c in geno.funcs]
    if length(childfuncs) == 0
        newroot = rand(rng, target_node.children)
        return rmfunc(geno, target_node, newroot, Pair{ExprNode, ExprNode}[])
    end
    # This will serve as the new root node
    newroot = rand(rng, childfuncs)
    # set the parent of the new root node to the parent of the target node
    leafsubs = Pair{ExprNode, ExprNode}[]
    childfuncs = shuffle(rng, filter(x -> x != newroot, childfuncs))
    leaves = getleaves(newroot)
    while length(childfuncs) > 0
        child = rand(rng, childfuncs)
        childfuncs = filter(x -> x != child, childfuncs)
        leaf = rand(rng, leaves)
        leaves = filter(x -> x != leaf, leaves)
        leaves = vcat(leaves, getleaves(child))
        push!(leafsubs, child => leaf)
    end
    rmfunc(geno, target_node, newroot, leafsubs)
end

function getchildnodes(root::ExprNode)
    nodes = ExprNode[]
    for c in root.children
        push!(nodes, c)
        if length(c.children) > 0
            nodes = vcat(nodes, getchildnodes(c))
        end
    end
    nodes
end

function getparentnodes(root::ExprNode)
    nodes = ExprNode[]
    if root.parent !== nothing
        push!(nodes, root.parent)
        nodes = vcat(nodes, getparentnodes(root.parent))
    end
    nodes
end

function swapnode(
    geno::GPGeno, 
    node1::ExprNode, 
    node2::ExprNode
)
    n1parent = node1.parent
    node1.parent = node2.parent
    if node2.parent !== nothing
        idx = findfirst(x -> x == node2, node2.parent.children)
        node2.parent.children[idx] = node1
    else
        geno.root = node1
    end
    node2.parent = n1parent

    if n1parent !== nothing
        idx = findfirst(x -> x == node1, n1parent.children)
        n1parent.children[idx] = node2
    else
        geno.root = node2
    end
    geno
end

function swapnode(rng::AbstractRNG, ::GPMutator, geno::GPGeno)
    geno = deepcopy(geno)
    allchildren = setdiff(geno.nodes, Set([geno.root]))
    node1 = rand(rng, allchildren)
    subtree_nodes = [getparentnodes(node1); node1; getchildnodes(node1)]
    swappable = setdiff(allchildren, subtree_nodes)
    node2 = rand(rng, swappable)
    swapnode(geno, node1, node2)
end

function dummytree()
    n1 = ExprNode(+)
    n2 = ExprNode(-, n1)
    n3 = ExprNode(*, n1)
    n1.children = [n2, n3]
    n4 = ExprNode(0, n2)
    n5 = ExprNode(1, n2)
    n2.children = [n4, n5]
    n6 = ExprNode(2, n3)
    n7 = ExprNode(3, n3)
    n3.children = [n6, n7]
    return n1
end

function ExprNode(rng::AbstractRNG, m::GPMutator, v::Union{FuncAlias, Terminal})
    if v in keys(m.terms)
        return ExprNode(v, nothing, Nothing[])
    end
    c = [rand(rng, keys(m.terms)) for _ in 1:m.funcs[v]]
    ExprNode(v, nothing, c)
end

function make_readtape(tape::Vector{Float64}) 
    i::Int = 1
    function read()
        val = tape[i]
        i = i == Base.length(tape) ? 1 : i + 1
        return val
    end
    read
end

abstract type TerminalFunctor end

mutable struct TapeReaderTerminalFunctor{T <: Real} <: TerminalFunctor
    head::Int
    tape::Vector{T}
end

mutable struct ConstantTerminalFunctor{T <: Real} <: TerminalFunctor
    val::T
end

function(terminal::ConstantTerminalFunctor)()
    terminal.val
end

function TapeReaderTerminalFunctor(tape::Vector{<:Real})
    TapeReaderTerminalFunctor(1, tape)
end

function (r::TapeReaderTerminalFunctor)()
    val = r.tape[r.head]
    r.head = r.head == 1 ? Base.length(r.tape) : r.head - 1
    val
end

function symcompile!(expr::Expr, tfs::Dict{Symbol, <:TerminalFunctor})
    for i in 1:length(expr.args)
        if isa(expr.args[i], Symbol)
            expr.args[i] = Expr(:call, tfs[expr.args[i]])
        elseif isa(expr.args[i], Expr)
            symcompile!(expr.args[i], sym, func)
        end
    end
end


function radianshift(x::Real)
    x - (floor(x / 2π) * 2π)
end

function simulate(n::Int, expr1::Expr, expr2::Expr, outfunc::Function = x -> x)
    init_expr1 = copy(expr1)
    init_expr2 = copy(expr2)
    symcompile!(init_expr1, Dict(:read => ConstantTerminalFunctor(0.0)))
    symcompile!(init_expr2, Dict(:read => ConstantTerminalFunctor(0.0)))
    tape1 = [eval(init_expr1)]
    tape2 = [eval(init_expr2)]
    tr1 = TapeReaderTerminalFunctor(tape2)
    tr2 = TapeReaderTerminalFunctor(tape1)
    expr1 = copy(expr1)
    expr2 = copy(expr2)
    symcompile!(expr1, Dict(:read => tr1))
    symcompile!(expr2, Dict(:read => tr2))
    for i in 1:n - 1
        tr1.head = i 
        tr2.head = i
        v1 = eval(expr1)
        v2 = eval(expr2)
        v1 = outfunc(v1)
        v2 = outfunc(v2)
        push!(tape1, v1)
        push!(tape2, v2)
    end
    tape1, tape2
end