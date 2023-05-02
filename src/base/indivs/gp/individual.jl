mutable struct GPLog
    mykey::String
    otherkey::String
    myscore::Float32
    otherscore::Float32
    my_otape::Vector{Float16}
    other_otape::Vector{Float16}
end

mutable struct GPIndiv <: AbstractCoevIndividual
    tgp::TreeGP
    key::String
    keydict::Dict{String, String}
    expr::Expr
    tape::Vector{Float64}
    disco::Union{DiscoRecord, Nothing}
    interactions::Union{Dict{String, GPLog}, Nothing}
end

function GPIndiv(key::String, genkey::String;
                 tape = Float64[π],
                 expr = Expr(:call, :write, Expr(:call, :read)),
                 tgp::TreeGP=TreeGP())
    GPIndiv(tgp,
            key,
            Dict{String, String}("genkey" => genkey),
            expr,
            tape,
            nothing,
            nothing)
end

function mutate(indiv::GPIndiv)
    t = deepcopy(indiv.expr)
    i = rand(indiv.rng, 1:length(t) - 1)
    n = get_nfuncs(t[i])
    r = rand(rng)
    size_subtree = if r < 1/3
        max(n - 1, 0)
    elseif r < 2
        n
    else
        n + 1
    end
    t[i] = randtreefunc(indiv.rng, indiv.tgp, size_subtree)
    t
end


function mutate(rng::AbstractRNG, t::TreeGP, expr::Expr)
    t = deepcopy(expr)
    i = rand(rng, 1:length(t) - 1)
    n = get_nfuncs(t[i])
    r = rand(rng)
    size_subtree = if r < 1/3
        max(n - 1, 0)
    elseif r < 2
        n
    else
        n + 1
    end
    t[i] = randtreefunc(rng, t, size_subtree)
    t
end
