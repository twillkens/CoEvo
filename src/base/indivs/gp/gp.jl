export make_readtape, make_writetape, tournament, crosstree
export pdiv, aq, pexp, plog, psqrt, psin, pcos, ppow, cond
export subtree, point, hoist, shrink
export GPLog, GPIndiv, TreeGP, randterm, randtree
export GPPopulation
export Terminal, interact
#include("expressions.jl")
const Terminal = Union{Symbol, Real, Function}
const FuncAlias = Union{Symbol, Function}

export Terminal
export FuncAlias

"""
Implementation of Koza-type (tree-based) Genetic Programming

The constructor takes following keyword arguments:

- `populationSize`: The size of the population
- `terminals`: A dictionary of terminals with their their corresponding dimensionality
    - This dictionary contains (`Terminal`, `Int`) pairs
    - The terminals can be any symbols (variables), constat values, or 0-arity functions.
- `functions`: A collection of functions with their corresponding arity.
    - This dictionary contains (`Function`, `Int`) pairs
- `initialization`: A strategy for population initialization (default: `:grow`)
    - Possible values: `:grow` and `:full`
- `mindepth`: Minimal depth of the expression (default: `0`)
- `maxdepth`: Maximal depth of the expression (default: `3`)
- `mutation`: A mutation function (default: [`crosstree`](@ref))
- `crossover`: A crossover function (default: [`subtree`](@ref))
- `simplify`: An expression simplification function (default: `:nothing`)
- `optimizer`: An evolutionary optimizer used for evolving the expressions (default: [`GA`](@ref))
    - Use `mutation` and `crossover` parameters to specify GP-related mutation operation.
    - Use `selection` parameter to specify the offspring selection procedure
"""

Base.@kwdef struct TreeGP
    terminals::Dict{Terminal, Int} = Dict([
        (:read, 1),
        (randfloat, 1),
    ])
    functions::Dict{FuncAlias, Int} = Dict([
        #(:write, 1),                                    
        (psin, 1),
        (+, 2),
    ])
    mindepth::Int = 0
    maxdepth::Int = 3
    initialization::Symbol = :grow
end

"""
    randterm(t::TreeGP)

Returns a random terminal given the specification from the `TreeGP` object `t`.
"""
function randterm(rng::AbstractRNG, t::TreeGP)
    term = rand(rng, keys(t.terminals))
    if isa(term, Symbol) || isa(term, Real)
        term
    elseif isa(term, Function)
        term(rng) # terminal functions must accept RNG as an argument
    else
        throw(ArgumentError("Terminal must be a Symbol, Real, or Function"))
    end
end

randterm(t::TreeGP) = randterm(default_rng(), t)

"""
    rand(t::TreeGP, maxdepth=2; mindepth=maxdepth-1)::Expr

Create a random expression tree given the specification from the `TreeGP` object `t`.
"""

function mutate(rng::AbstractRNG, t::TreeGP, expr::Expr)
    expr = deepcopy(expr)
    i = rand(rng, 1:length(expr) - 1)
    n = get_nfuncs(expr[i])
    r = rand(rng)
    size_subtree = if r < 1 / 3
        max(n - 1, 0)
    elseif r < 2 / 3
        n
    else
        n + 1
    end
    #size_subtree = get_nfuncs(expr[i]) + 1
    new_subtree = randtreefunc(rng, t, size_subtree)
    println("old expr: ", expr)
    println("old subtree at index ", i," :", expr[i])
    println("n change: ", size_subtree - n)
    println("new_subtree: ", new_subtree)
    expr[i] = new_subtree
    println("new expr: ", expr)
    #expr
end

function randtreefunc(rng::AbstractRNG, t::TreeGP, nfunc::Int)
    if nfunc == 0
        return randterm(rng, t)
    end
    root = Base.rand(rng, keys(t.functions))
    args = Any[]
    nfunc = nfunc - 1
    if t.functions[root] == 1
        arg = randtreefunc(rng, t, nfunc)
        push!(args, arg)
    elseif t.functions[root] == 2
        nfunc1 = rand(rng, 0:nfunc)
        nfunc2 = nfunc - nfunc1
        arg1 = randtreefunc(rng, t, nfunc1)
        arg2 = randtreefunc(rng, t, nfunc2)
        push!(args, arg1)
        push!(args, arg2)
    end
    Expr(:call, root, args...)
end

randtreefunc(t::TreeGP, nfunc::Int) = randtreefunc(default_rng(), t, nfunc)

function randtree(rng::AbstractRNG, t::TreeGP, maxdepth::Int=2; mindepth::Int=maxdepth-1)
    @assert maxdepth > mindepth "`maxdepth` must be larger then `mindepth`"
    tl = length(t.terminals)
    fl = length(t.functions)
    root = if (maxdepth == 0  || ( t.initialization == :grow && Base.rand(rng) < tl/(tl+fl) ) ) && mindepth <= 0
        randterm(rng, t)
    else
        Base.rand(rng, keys(t.functions))
    end
    #if isa(root, Function)
    if root in Set(keys(t.functions))
        args = Any[]
        for i in 1:t.functions[root]
            arg = randtree(rng, t, maxdepth-1, mindepth=mindepth-1)
            push!(args, arg)
        end
        Expr(:call, root, args...)
    else
        return root
    end
end

function subtree(method::TreeGP; growth::Real = 0.0)
    function mutation(recombinant::Expr; rng::AbstractRNG=default_rng())
        i = Base.rand(rng, 1:nodes(recombinant)-1)
        th = depth(recombinant, recombinant[i])
        maxh = if growth > 0
            rh = height(recombinant)
            mh = max(method.maxdepth, Base.rand(rng, rh:rh*(1+growth)))
            round(Int, mh)
        else
            method.maxdepth
        end
        recombinant[i] = randtree(rng, method, max(0, maxh-th))
        recombinant
    end
    return mutation
end


"""
    point(method::TreeGP)

Returns an in-place expression mutation function that replaces an arbitrary node in the tree by the randomly selected one.
Node replacement mutation is similar to bit string mutation in that it randomly changes a point in the individual.
To ensure the tree remains legal, the replacement node has the same number of arguments as the node it is replacing [^6].
"""
function point(method::TreeGP)
    function mutation(recombinant::Expr; rng::AbstractRNG=default_rng())
        i = rand(rng, 0:nodes(recombinant)-1)
        nd = recombinant[i]
        if isa(nd, Expr)
            aty = length(nd.args)-1
            atyfnc = filter(kv -> kv[2] == aty, method.functions)
            if length(atyfnc) > 0
                nd.args[1] = atyfnc |> keys |> rand
            end
        else
            recombinant[i] = randterm(rng, method)
        end
        recombinant
    end
    return mutation
end