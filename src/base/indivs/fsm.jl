export FSMIndiv, FSMGeno, FSMPheno, FSMPhenoCfg
export genotype, LinkDict, StateSet, act, FSMIndivConfig
export FSMIndivArchiver, FSMSetPheno, FSMMinPheno


LinkDict = Dict{Tuple{String, Bool}, String}
StateSet = Set{String}

struct FSMGeno{T} <: Genotype
    start::T
    ones::Set{T}
    zeros::Set{T}
    links::Dict{Tuple{T, Bool}, T}
end


# Phenotype

abstract type FSMPheno{T} <: Phenotype end

struct FSMSetPheno{T} <: FSMPheno{T}
    ikey::IndivKey
    start::T
    ones::Set{T}
    zeros::Set{T}
    links::Dict{Tuple{T, Bool}, T}
end

struct FSMMinPheno{T} <: FSMPheno{T}
    ikey::IndivKey
    start::Tuple{T, Bool}
    links::Dict{Tuple{T, Bool}, Tuple{T, Bool}}
end

function FSMMinPheno(pheno::FSMSetPheno)
    newlinks = Dict(
        ((source, bit) => (target, target in pheno.ones))
        for ((source, bit), target) in pheno.links
    )
    FSMMinPheno(pheno.ikey, (pheno.start, pheno.start in pheno.ones), newlinks)
end


# Indiv

struct FSMIndiv{G <: FSMGeno} <: Individual
    ikey::IndivKey
    geno::G
    mingeno::G
    pids::Set{UInt32}
end

function FSMIndiv(ikey::IndivKey, geno::FSMGeno, mingeno::FSMGeno)
    FSMIndiv(ikey, geno, mingeno, Set{UInt32}())
end

function FSMIndiv(spid::Symbol, iid::UInt32, geno::FSMGeno, mingeno::FSMGeno, pids::Set{UInt32})
    FSMIndiv(IndivKey(spid, iid), geno, mingeno, pids)
end

function Base.getproperty(indiv::FSMIndiv, s::Symbol)
    if s == :ones
        return indiv.geno.ones
    elseif s == :zeros
        return indiv.geno.zeros
    elseif s == :links
        return indiv.geno.links
    elseif s == :start
        return indiv.geno.start
    elseif s == :spid
        return indiv.ikey.spid
    elseif s == :iid
        return indiv.ikey.iid
    else
        return getfield(indiv, s)
    end
end

function clone(iid::UInt32, parent::FSMIndiv)
    ikey = IndivKey(parent.spid, iid)
    FSMIndiv(ikey, parent.geno, parent.mingeno, Set([parent.iid]))
end


# IndivConfig

Base.@kwdef struct FSMIndivConfig{T} <: IndivConfig
    spid::Symbol
    dtype::Type{<:T}
end

function getstart(::FSMIndivConfig{String}, sc::SpawnCounter)
    string(gid!(sc))
end

function getstart(::FSMIndivConfig{UInt32}, sc::SpawnCounter)
    gid!(sc)
end

function getstart(::FSMIndivConfig{Int}, sc::SpawnCounter)
    Int(gid!(sc))
end

function(cfg::FSMIndivConfig)(rng::AbstractRNG, sc::SpawnCounter)
    ikey = IndivKey(cfg.spid, iid!(sc))
    startstate = getstart(cfg, sc)
    ones, zeros = rand(rng, Bool) ?
        (Set([startstate]), Set{cfg.dtype}()) : (Set{cfg.dtype}(), Set([startstate]))
    geno = FSMGeno(
        startstate,
        ones,
        zeros,
        Dict(((startstate, true) => startstate, (startstate, false) => startstate)))
    FSMIndiv(ikey, geno, geno)
end

function(cfg::FSMIndivConfig)(sc::SpawnCounter, geno::FSMGeno)
    ikey = IndivKey(cfg.spid, iid!(sc))
    geno = FSMGeno(geno.start, geno.ones, geno.zeros, geno.links)
    mingeno = minimize(geno)
    FSMIndiv(ikey, geno, mingeno)
end

function(cfg::FSMIndivConfig)(sc::SpawnCounter, n::Int, geno::FSMGeno)
    ikeys = [IndivKey(cfg.spid, iid!(sc)) for _ in 1:n]
    genos = [FSMGeno(geno.start, geno.ones, geno.zeros, geno.links) for _ in 1:n]
    mingenos = [minimize(geno) for geno in genos]
    [FSMIndiv(ikey, geno, mingeno) for (ikey, geno, mingeno) in zip(ikeys, genos, mingenos)]
end

function(cfg::FSMIndivConfig)(::AbstractRNG, sc::SpawnCounter, npop::Int, indiv::FSMIndiv)
    cfg(sc, npop, indiv.geno)
end


# PhenoConfig

Base.@kwdef struct FSMPhenoCfg <: PhenoConfig
    usemin::Bool = true
    usesets::Bool = false
end

Base.@kwdef struct FSMMinPhenoCfg <: PhenoConfig
    usemin::Bool = true
end

function(cfg::FSMPhenoCfg)(ikey::IndivKey, geno::FSMGeno)
    if cfg.usesets
        return FSMSetPheno(ikey, geno.start, geno.ones, geno.zeros, geno.links)
    end
    newlinks = Dict(
        ((source, bit) => (target, target in geno.ones))
        for ((source, bit), target) in geno.links
    )
    FSMMinPheno(
        ikey,
        (geno.start, geno.start in geno.ones),
        newlinks
    )
end

function(cfg::FSMPhenoCfg)(indiv::FSMIndiv)
    cfg(indiv.ikey, cfg.usemin ? indiv.mingeno : indiv.geno)
end


# Loading

function FSMIndiv(spid::Symbol, iid::UInt32, geno::FSMGeno, mingeno::FSMGeno)
    FSMIndiv(IndivKey(spid, iid), geno, mingeno)
end

function FSMIndiv(
    ikey::IndivKey, start::String, ones::Set{T}, zeros::Set{T}, links::Dict{Tuple{T, Bool}, T}
) where T
    geno = FSMGeno(start, ones, zeros, links)
    mingeno = minimize(geno)
    FSMIndiv(ikey, geno, mingeno)
end

function FSMIndiv(spid::String, iid::String, igroup::JLD2.Group)
    FSMIndiv(Symbol(spid), parse(UInt32, iid), igroup)
end

function FSMIndiv(ikey::IndivKey, igroup::JLD2.Group)
    FSMIndiv(ikey.spid, ikey.iid, igroup)
end


# Archiver

Base.@kwdef struct FSMIndivArchiver <: Archiver
    log_popids::Bool = true
    savegeno::Bool = true
    savemingeno::Bool = false
end

function(a::FSMIndivArchiver)(geno_group::JLD2.Group, geno::FSMGeno)
    geno_group["start"] = geno.start
    geno_group["ones"] = collect(geno.ones)
    geno_group["zeros"] = collect(geno.zeros)
    geno_group["sources"] = [source for ((source, _), _) in geno.links]
    geno_group["bits"] = [bit for ((_, bit), _) in geno.links]
    geno_group["targets"] = [target for ((_, _), target) in geno.links]
end

function(a::FSMIndivArchiver)(children_group::JLD2.Group, child::FSMIndiv)
    cgroup = make_group!(children_group, child.iid)
    cgroup["pids"] = child.pids
    if a.savegeno
        geno_group = make_group!(cgroup, "geno")
        a(geno_group, child.geno)
    end
    if a.savemingeno
        mingeno_group = make_group!(cgroup, "mingeno")
        a(mingeno_group, child.mingeno)
    end
end

function(a::FSMIndivArchiver)(geno_group::JLD2.Group)
    start = geno_group["start"]
    ones = Set(geno_group["ones"])
    zeros = Set(geno_group["zeros"])
    links = Dict(
        (s, b) => t for (s, b, t) in
        zip(geno_group["sources"], geno_group["bits"], geno_group["targets"])
    )
    FSMGeno(start, ones, zeros, links)
end

function(a::FSMIndivArchiver)(spid::Symbol, iid::UInt32, igroup::JLD2.Group)
    pids = igroup["pids"]
    if a.savegeno && a.savemingeno
        geno = a(igroup["geno"])
        mingeno = a(igroup["mingeno"])
        FSMIndiv(spid, iid, geno, mingeno, pids)
    elseif !a.savegeno && a.savemingeno
        mingeno = a(igroup["mingeno"])
        FSMIndiv(spid, iid, mingeno, mingeno, pids)
    elseif a.savegeno && !a.savemingeno
        geno = a(igroup["geno"])
        mingeno = minimize(geno)
        FSMIndiv(spid, iid, geno, mingeno, pids)
    else
        throw(ArgumentError("FSMIndivArchiver requires at least one of geno or mingeno to load"))
    end
end

function(a::FSMIndivArchiver)(spid::String, iid::String, igroup::JLD2.Group)
    a(Symbol(spid), parse(UInt32, iid), igroup)
end

function(cfg::IndivConfig)(spid::String, iid::String, igroup::JLD2.Group)
    cfg(Symbol(spid), parse(UInt32, iid), igroup)
end

# equals

Base.@kwdef mutable struct AliasCounter
    i::Int = 0
end

function(cnt::AliasCounter)()
    cnt.i += 1
    cnt.i
end

function Base.hash(x::FSMGeno, h::UInt)
    hash(aliasgeno(x), h)
end

function Base.:(==)(x::FSMGeno{T}, y::FSMGeno{T}) where T
    if length(x.ones) != length(y.ones) || length(x.zeros) != length(y.zeros)
        return false
    end
    aliasgeno(x) == aliasgeno(y)
end

function aliasgeno(geno::FSMGeno)
    adict, cnt = build_aliasdict(geno)
    [push!(adict, s => cnt()) for s in geno.ones if s ∉ keys(adict)]
    [push!(adict, s => cnt()) for s in geno.zeros if s ∉ keys(adict)]
    aliasones = Set(adict[source] for source in geno.ones)
    aliaszeros = Set(adict[source] for source in geno.zeros)
    aliaslinks = Dict(
        (adict[source], bit) => (adict[target], adict[target] in aliasones)
        for ((source, bit), target) in geno.links
    )
    adict[geno.start], aliasones, aliaszeros, aliaslinks
end

function build_aliasdict(
    geno::FSMGeno{T},
    s::T = geno.start,
    adict::Dict{T, Int} = Dict{T, Int}(), 
    cnt::AliasCounter = AliasCounter()
) where T
    if s in keys(adict)
        return adict, cnt
    end
    adict[s] = cnt()
    build_aliasdict(geno, geno.links[(s, true)], adict, cnt)
    build_aliasdict(geno, geno.links[(s, false)], adict, cnt)
end