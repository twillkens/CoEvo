export VectorIndiv, VectorGeno
export make_genotype
export ScalarGene
export VectorIndivConfig
export genotype, clone, testkey

Base.@kwdef struct VectorIndivConfig <: IndivConfig
    spkey::String
    sc::SpawnCounter
    rng::AbstractRNG
    dtype::Type{<:Real}
    width::Int
end

struct VectorIndiv{G <: ScalarGene} <: Individual
    spkey::String
    iid::Int
    gen::Int
    genes::Vector{G}
    pids::Set{Int}
    outcomes::Set{ScalarOutcome}
end

function VectorIndiv(spkey::String, iid::Int, genes::Vector{<:ScalarGene}, )
    VectorIndiv(spkey, iid, 1, genes, Set{Int}(), Set{ScalarOutcome}())
end

function testkey(indiv::VectorIndiv)
    string(indiv.spkey, KEY_SPLIT_TOKEN, indiv.iid)
end

function clone(iid::Int, gen::Int, parent::VectorIndiv)
    VectorIndiv(parent.spkey, iid, gen, parent.genes, Set([parent.iid]), Set{ScalarOutcome}())
end

struct VectorGeno{T <: Real} <: Genotype
    spkey::String
    iid::Int
    genes::Vector{T}
end

function genotype(indiv::VectorIndiv{<:ScalarGene})
    genes = [g.val for g in indiv.genes]
    VectorGeno(indiv.spkey, indiv.iid, genes)
end

function VectorIndiv(spkey::String, iid::Int, gids::Vector{Int}, vals::Vector{<:Real})
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

function(m::BitflipMutator)(indiv::VectorIndiv)
    newgenes = ScalarGene{Bool}[]
    for gene in indiv.genes
        if rand(m.rng) < m.mutrate
            newgene = ScalarGene(gid!(m.sc), indiv.iid, indiv.gen, !gene.val)
            push!(newgenes, newgene)
        else
            push!(newgenes, gene)
        end
    end
    VectorIndiv(indiv.spkey, indiv.iid, indiv.gen, newgenes, indiv.pids, indiv.outcomes)
end

# function(r::NPointCrossoverRecombiner)(variator::Variator, gen::Int,
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