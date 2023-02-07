export VectorIndiv, VectorGeno
export make_genotype
export ScalarGene
export VectorIndivConfig
export genotype, clone

Base.@kwdef struct VectorIndivConfig <: IndivConfig
    spkey::String
    sc::SpawnCounter
    rng::AbstractRNG
    dtype::Type{<:Real}
    width::Int
end

struct VectorIndiv{G <: ScalarGene} <: Individual
    spkey::String
    iid::UInt32
    gen::UInt16
    genes::Vector{G}
    pids::Set{UInt32}
end

function VectorIndiv(spkey::String, iid::UInt32, genes::Vector{<:ScalarGene}, )
    VectorIndiv(spkey, iid, UInt16(1), genes, Set{UInt32}())
end

function clone(iid::UInt32, gen::UInt16, parent::VectorIndiv)
    VectorIndiv(parent.spkey, iid, gen, parent.genes, Set([parent.iid]))
end

struct VectorGeno{T <: Real} <: Genotype
    spkey::String
    iid::UInt32
    genes::Vector{T}
end

function genotype(indiv::VectorIndiv{<:ScalarGene})
    genes = [g.val for g in indiv.genes]
    VectorGeno(indiv.spkey, indiv.iid, genes)
end

function VectorIndiv(spkey::String, iid::UInt32, gids::Vector{UInt32}, vals::Vector{<:Real})
    genes = [ScalarGene(gid, iid, val) for (gid, val) in zip(gids, vals)]
    VectorIndiv(spkey, iid, genes,)
end

function(cfg::VectorIndivConfig)()
    VectorIndiv(
        cfg.spkey,
        iid!(cfg.sc),
        gids!(cfg.sc, cfg.width),
        rand(cfg.rng, cfg.dtype, cfg.width))
end

function(cfg::VectorIndivConfig)(n_indiv::Int)
    Set([cfg() for _ in 1:n_indiv])
end

function(cfg::VectorIndivConfig)(n_indiv::Int, vec::Vector{<:Real})
    Set([VectorIndiv(spkey, iid!(cfg.sc), gids!(cfg.sc, cfg.width), vec)
    for _ in 1:n_indiv])
end

function(cfg::VectorIndivConfig)(n_indiv::Int, val::Real)
    Set([VectorIndiv(cfg.spkey, iid!(cfg.sc),
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