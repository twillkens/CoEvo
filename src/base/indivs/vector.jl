export VectorIndiv, VectorGeno
export make_genotype
export ScalarGene
export VectorIndivConfig
export genotype, clone, getgids, getvals

Base.@kwdef struct VectorIndivConfig <: IndivConfig
    spid::Symbol
    sc::SpawnCounter
    rng::AbstractRNG
    dtype::Type{<:Real}
    width::Int
end

struct VectorIndiv{G <: ScalarGene} <: Individual
    ikey::IndivKey
    genes::Vector{G}
    pids::Set{UInt32}
end

function Base.getproperty(indiv::Individual, prop::Symbol)
    if prop == :spid
        indiv.ikey.spid
    elseif prop == :iid
        indiv.ikey.iid
    elseif prop == :gids
        getgids(indiv)
    elseif prop == :vals
        getvals(indiv)
    else
        getfield(indiv, prop)
    end
end

function getgids(genes::Vector{<:ScalarGene})
    [g.gid for g in genes]
end

function getgids(indiv::VectorIndiv)
    getgids(indiv.genes)
end

function getvals(indiv::VectorIndiv)
    [g.val for g in indiv.genes]
end

function VectorIndiv(spid::Symbol, iid::UInt32, genes::Vector{<:ScalarGene}, )
    VectorIndiv(IndivKey(spid, iid), genes, Set{UInt32}())
end

function clone(iid::UInt32, parent::VectorIndiv)
    VectorIndiv(IndivKey(parent.spid, iid), parent.genes, Set([parent.iid]))
end

struct VectorGeno{T <: Real} <: Genotype
    ikey::IndivKey
    genes::Vector{T}
end

function genotype(indiv::VectorIndiv{<:ScalarGene})
    genes = [g.val for g in indiv.genes]
    VectorGeno(indiv.ikey, genes)
end

function VectorIndiv(spid::Symbol, iid::UInt32, gids::Vector{UInt32}, vals::Vector{<:Real})
    genes = [ScalarGene(gid, val) for (gid, val) in zip(gids, vals)]
    VectorIndiv(spid, iid, genes)
end

function VectorIndiv(spid::Symbol, iid::Int, gids::Vector{UInt32}, vals::Vector{<:Real})
    VectorIndiv(spid, UInt32(iid), gids, vals)
end

function(cfg::VectorIndivConfig)()
    VectorIndiv(
        cfg.spid,
        iid!(cfg.sc),
        gids!(cfg.sc, cfg.width),
        rand(cfg.rng, cfg.dtype, cfg.width))
end

function(cfg::VectorIndivConfig)(n_indiv::Int)
    Set([cfg() for _ in 1:n_indiv])
end

function(cfg::VectorIndivConfig)(n_indiv::Int, vec::Vector{<:Real})
    Set([VectorIndiv(spid, iid!(cfg.sc), gids!(cfg.sc, cfg.width), vec)
    for _ in 1:n_indiv])
end

function(cfg::VectorIndivConfig)(n_indiv::Int, val::Real)
    Set([VectorIndiv(cfg.spid, iid!(cfg.sc),
        gids!(cfg.sc, cfg.width), fill(val, cfg.width))
    for _ in 1:n_indiv])
end


# function(r::NPointCrossoverRecombiner)(variator::Variator, gen::UInt16,
#         childkeys::Vector{String}, parents::Dict{String, I}) where {I <: Individual}
#     children = VectorIndiv[]
#     for i in 1:2:length(childkeys)
#         mother, father = sample(v.rng, collect(values(parents)), 2)
#         n_cuts = min(v.width - 1, r.n_points)
#         cutpts = sort(sample(v.rng, 1:v.width, n_cuts))
#         normal = true
#         sisgenes = VectorGene[]
#         brogenes = VectorGene[]
#         for (i, (mgene, fgene)) in enumerate(zip(mother.genes, father.genes))
#             if i ∈ cutpts
#                 push!(brogenes, fgene)
#                 push!(sisgenes, mgene)
#                 normal = false
#             else
#                 push!(brogenes, mgene)
#                 push!(sisgenes, fgene)
#                 normal = !normal
#             end
#         end
#         pset = Set([mother.key, father.key])
#         bro = VectorIndiv(childkeys[i], gen, brogenes, pset, Set{Outcome}())
#         sis = VectorIndiv(childkeys[i + 1], gen, sisgenes, pset, Set{Outcome}())
#         append!(children, [bro, sis])
#     end
#     children
# end