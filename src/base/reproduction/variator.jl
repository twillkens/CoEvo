export Variator
export gid!, iid!, gids!, iids!

Base.@kwdef mutable struct Variator{R <: Recombiner, M <: Mutator}
    λ::Int
    iid::Int = 1
    gid::Int = 1
    recombiner::R 
    mutators::Vector{M}
end

function(v::Variator)(gen::Int, parents::Vector{<:Individual})
    iids = iids!(v, v.λ)
    children = v.recombiner(v, gen, iids, parents)
    for mutator in v.mutators
        children = mutator(v, gen, children)
    end
    children
end

function gid!(v::Variator)
    gid = v.gid
    v.gid += 1
    gid
end

function iid!(v::Variator)
    iid = v.iid
    v.iid += 1
    iid
end

function gids!(v::Variator, n::Int)
    [gid!(v) for _ in 1:n]
end

function iids!(v::Variator, n::Int)
    [iid!(v) for _ in 1:n]
end