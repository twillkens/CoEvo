export VectorIndiv, VectorGene, VectorIndiv, VectorVariator, VectorGeno
export make_genotype
export ScalarGene
export VectorIndivConfig

struct ScalarGene{T <: Real} <: Gene
    gid::Int
    iid::Int
    gen::Int
    val::T
end

struct VectorGeno{T <: Real} <: Genotype
    key::String
    genes::Vector{T}
end

struct VectorIndiv{G <: ScalarGene, O <: Outcome} <: Individual
    iid::Int
    gen::Int
    genes::Vector{G}
    pids::Set{Int}
    outcomes::Set{O}
end

function genokey(spkey::String, iid::Int)
    string(spkey, KEY_SPLIT_TOKEN, iid)
end

function genotype(spkey::String, indiv::VectorIndiv)
    genes = [g.val for g in indiv.genes]
    VectorGeno(genokey(spkey, indiv.iid), genes)
end

struct VectorIndivConfig
    rng::AbstractRNG
    dtype::Type{<:Real}
    width::Int
end

function VectorIndiv(iid::Int, gids::Vector{Int}, vals::Vector{<:Real})
    genes = [ScalarGene(gid, 1, ikey, val) for (gid, val) in zip(gids, vals)]
    VectorIndiv(iid, 1, genes, Set{Int}(), Set{Outcome}())
end

function(cfg::VectorIndivConfig)(iid::Int)
    VectorIndiv(
        iid,
        collect(1:cfg.width),
        rand(cfg.rng, cfg.dtype, cfg.width))
end

function(cfg::VectorIndivConfig)(variator::VVariator, iids::Vector{Int})
    [VectorIndiv(
        iid,
        gids!(variator, cfg.width),
        rand(cfg.rng, cfg.dtype, cfg.width))
    for iid in iids]
end

function(cfg::VectorIndivConfig)(variator::VVariator, iids::Vector{Int}, vec::Vector{<:Real})
    [VectorIndiv(iid, gids!(variator, cfg.width), vec) for iid in iids]
end

function(cfg::VectorIndivConfig)(variator::VVariator, iids::Vector{Int}, val::Real)
    vec = fill(val, cfg.width)
    [VectorIndiv(iid, gids!(variator, cfg.width), vec) for iid in iids]
end

function(m::BitflipMutator)(variator::VVariator, indiv::VectorIndiv)
    newgenes = ScalarGene{Bool}[]
    for gene in indiv.genes
        if rand(variator.rng) < m.mutrate
            newgene = ScalarGene(gid!(variator), indiv.iid, indiv.gen, !gene.val)
            push!(newgenes, newgene)
        else
            push!(newgenes, gene)
        end
    end
    VectorIndiv(indiv.iid, indiv.gen, newgenes, indiv.pids, indiv.outcomes)
end

function(r::NPointCrossoverRecombiner)(variator::VectorVariator, gen::Int,
        childkeys::Vector{String}, parents::Dict{String, I}) where {I <: Individual}
    children = VectorIndiv[]
    for i in 1:2:length(childkeys)
        mother, father = sample(v.rng, collect(values(parents)), 2)
        n_cuts = min(v.width - 1, r.n_points)
        cutpts = sort(sample(v.rng, 1:v.width, n_cuts))
        normal = true
        sisgenes = VectorGene[]
        brogenes = VectorGene[]
        for (i, (mgene, fgene)) in enumerate(zip(mother.genes, father.genes))
            if i ∈ cutpts
                push!(brogenes, fgene)
                push!(sisgenes, mgene)
                normal = false
            else
                push!(brogenes, mgene)
                push!(sisgenes, fgene)
                normal = !normal
            end
        end
        pset = Set([mother.key, father.key])
        bro = VectorIndiv(childkeys[i], gen, brogenes, pset, Set{Outcome}())
        sis = VectorIndiv(childkeys[i + 1], gen, sisgenes, pset, Set{Outcome}())
        append!(children, [bro, sis])
    end
    children
end