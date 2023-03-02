export VectorIndiv, VectorGeno
export make_genotype
export ScalarGene
export VectorIndivConfig, VectorIndivArchiver
export genotype, clone, getgids, getvals


struct VectorIndiv{G <: ScalarGene} <: Individual
    ikey::IndivKey
    genes::Vector{G}
    pids::Set{UInt32}
end

Base.@kwdef struct VectorIndivConfig <: IndivConfig
    spid::Symbol
    dtype::Type{<:Real}
    width::Int
end

Base.@kwdef struct VectorIndivArchiver <: Archiver
    interval::Int = 1
    log_popids::Bool = true
end

function(a::VectorIndivArchiver)(children_group::JLD2.Group, child::VectorIndiv)
    cgroup = make_group!(children_group, child.iid)
    cgroup["gids"] = [gene.gid for gene in child.genes]
    cgroup["vals"] = [gene.val for gene in child.genes]
    cgroup["pids"] = collect(child.pids)
end

function Base.getproperty(indiv::VectorIndiv, prop::Symbol)
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

function Base.getproperty(indiv::Individual, prop::Symbol)
    if prop == :spid
        indiv.ikey.spid
    elseif prop == :iid
        indiv.ikey.iid
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

function VectorIndiv(spid::Symbol, iid::UInt32, genes::Vector{<:ScalarGene},)
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

function(cfg::VectorIndivConfig)(rng::AbstractRNG, sc::SpawnCounter)
    VectorIndiv(
        cfg.spid,
        iid!(sc),
        gids!(sc, cfg.width),
        rand(rng, cfg.dtype, cfg.width))
end

function(cfg::IndivConfig)(rng::AbstractRNG, sc::SpawnCounter, n_indiv::Int)
    indivs = [cfg(rng, sc) for _ in 1:n_indiv]
    Dict(indiv.ikey => indiv for indiv in indivs)
end

function(cfg::VectorIndivConfig)(
    ::AbstractRNG, sc::SpawnCounter, n_indiv::Int, vec::Vector{<:Real}
)
    indivs = [
        VectorIndiv(spid, iid!(sc), gids!(sc, cfg.width), vec)
        for _ in 1:n_indiv
    ]
    Dict(indiv.ikey => indiv for indiv in indivs)
end

function(cfg::VectorIndivConfig)(::AbstractRNG, sc::SpawnCounter, n_indiv::Int, val::Real)
    indivs = [
        VectorIndiv(
            cfg.spid, iid!(sc), gids!(sc, cfg.width), fill(val, cfg.width)
        ) for _ in 1:n_indiv
    ]
    Dict(indiv.ikey => indiv for indiv in indivs)
end

function(cfg::VectorIndivConfig)(spid::String, iid::String, igroup::JLD2.Group)
    genes = [ScalarGene(gid, val) for (gid, val) in zip(igroup["gids"], igroup["vals"])]
    pids = Set{UInt32}(igroup["pids"])
    VectorIndiv(IndivKey(spid, iid), genes, pids)
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