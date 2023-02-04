export VectorIndiv, VectorGeno
export make_genotype
export ScalarGene
export VectorIndivConfig
export genotype


Base.@kwdef struct VectorIndivConfig <: IndivConfig
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
    genes = [ScalarGene(gid, iid, 1, val) for (gid, val) in zip(gids, vals)]
    VectorIndiv(spkey, iid, 1, genes, Set{Int}(), Set{ScalarOutcome}())
end

function(cfg::VectorIndivConfig)(spkey::String, iid::Int)
    VectorIndiv(
        spkey,
        iid,
        collect(1:cfg.width),
        rand(cfg.rng, cfg.dtype, cfg.width))
end

function(cfg::VectorIndivConfig)(variator::Variator, spkey::String, iids::Vector{Int})
    [VectorIndiv(
        spkey,
        iid,
        gids!(variator, cfg.width),
        rand(cfg.rng, cfg.dtype, cfg.width))
    for iid in iids]
end

function(cfg::VectorIndivConfig)(variator::Variator, spkey::String, iids::Vector{Int}, vec::Vector{<:Real})
    [VectorIndiv(spkey, iid, gids!(variator, cfg.width), vec) for iid in iids]
end

function(cfg::VectorIndivConfig)(variator::Variator, spkey::String, iids::Vector{Int}, val::Real)
    vec = fill(val, cfg.width)
    [VectorIndiv(spkey, iid, gids!(variator, cfg.width), vec) for iid in iids]
end

function(m::BitflipMutator)(variator::Variator, indiv::VectorIndiv)
    newgenes = ScalarGene{Bool}[]
    for gene in indiv.genes
        if rand(variator.rng) < m.mutrate
            newgene = ScalarGene(gid!(variator), indiv.iid, indiv.gen, !gene.val)
            push!(newgenes, newgene)
        else
            push!(newgenes, gene)
        end
    end
    VectorIndiv(indiv.spkey, indiv.iid, indiv.gen, newgenes, indiv.pids, indiv.outcomes)
end

function(r::NPointCrossoverRecombiner)(variator::Variator, gen::Int,
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