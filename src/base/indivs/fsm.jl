export FSMIndiv, FSMGeno, FSMPheno, FSMPhenoCfg
export genotype, LinkDict, StateSet, act, FSMIndivConfig
export FSMIndivArchiver

LinkDict = Dict{Tuple{String, Bool}, String}
StateSet = Set{String}

struct FSMGeno{T} <: Genotype
    start::T
    ones::Set{T}
    zeros::Set{T}
    links::Dict{Tuple{T, Bool}, T}
end

struct FSMPheno{T} <: Phenotype
    ikey::IndivKey
    start::T
    ones::Set{T}
    zeros::Set{T}
    links::Dict{Tuple{T, Bool}, T}
end

struct FSMIndiv{G <: FSMGeno} <: Individual
    ikey::IndivKey
    geno::G
    pids::Set{UInt32}
end

function FSMIndiv(ikey::IndivKey, geno::FSMGeno)
    FSMIndiv(ikey, geno, Set{UInt32}())
end

function FSMIndiv(spid::Symbol, iid::UInt32, geno::FSMGeno, pids::Set{UInt32})
    FSMIndiv(IndivKey(spid, iid), geno, pids)
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
    FSMIndiv(ikey, parent.geno, Set([parent.iid]))
end

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
    FSMIndiv(ikey, geno)
end

function(cfg::FSMIndivConfig)(sc::SpawnCounter, geno::FSMGeno)
    ikey = IndivKey(cfg.spid, iid!(sc))
    geno = FSMGeno(geno.start, geno.ones, geno.zeros, geno.links)
    FSMIndiv(ikey, geno)
end

function(cfg::FSMIndivConfig)(sc::SpawnCounter, n::Int, geno::FSMGeno)
    ikeys = [IndivKey(cfg.spid, iid!(sc)) for _ in 1:n]
    genos = [FSMGeno(geno.start, geno.ones, geno.zeros, geno.links) for _ in 1:n]
    [FSMIndiv(ikey, geno) for (ikey, geno) in zip(ikeys, genos)]
end

function(cfg::FSMIndivConfig)(::AbstractRNG, sc::SpawnCounter, npop::Int, indiv::FSMIndiv)
    cfg(sc, npop, indiv.geno)
end


Base.@kwdef struct FSMPhenoCfg <: PhenoConfig
    minimize = true
end

function(cfg::FSMPhenoCfg)(indiv::FSMIndiv)
    indiv = cfg.minimize ? minimize(indiv) : indiv
    FSMPheno(indiv.ikey, indiv.start, indiv.ones, indiv.zeros, indiv.links)
end

function FSMIndiv(spid::Symbol, iid::UInt32, geno::FSMGeno)
    FSMIndiv(IndivKey(spid, iid), geno)
end

function FSMIndiv(
    ikey::IndivKey, start::String, ones::Set{T}, zeros::Set{T}, links::Dict{Tuple{T, Bool}, T}
) where T
    geno = FSMGeno(start, ones, zeros, links)
    FSMIndiv(ikey, geno)
end

function FSMIndiv(spid::String, iid::String, igroup::JLD2.Group)
    FSMIndiv(Symbol(spid), parse(UInt32, iid), igroup)
end

function FSMIndiv(ikey::IndivKey, igroup::JLD2.Group)
    FSMIndiv(ikey.spid, ikey.iid, igroup)
end

Base.@kwdef struct FSMIndivArchiver <: Archiver
    interval::Int = 1
    log_popids::Bool = true
    minimize::Bool = false
end

function(a::FSMIndivArchiver)(children_group::JLD2.Group, child::FSMIndiv)
    child = a.minimize ? minimize(child) : child
    cgroup = make_group!(children_group, child.iid)
    cgroup["start"] = child.start
    cgroup["ones"] = child.ones
    cgroup["zeros"] = child.zeros
    cgroup["sources"] = [source for ((source, _), _) in child.links]
    cgroup["bits"] = [bit for ((_, bit), _) in child.links]
    cgroup["targets"] = [target for ((_, _), target) in child.links]
    cgroup["pids"] = child.pids
end

function(cfg::FSMIndivConfig)(spid::Symbol, iid::UInt32, igroup::JLD2.Group)
    start = igroup["start"]
    ones = igroup["ones"]
    zeros = igroup["zeros"]
    links = Dict(
        (s, w) => t for (s, w, t) in zip(igroup["sources"], igroup["bits"], igroup["targets"])
    )
    pids = igroup["pids"]
    geno = FSMGeno(start, ones, zeros, links)
    FSMIndiv(spid, iid, geno, pids)
end

function(cfg::IndivConfig)(spid::String, iid::String, igroup::JLD2.Group)
    cfg(Symbol(spid), parse(UInt32, iid), igroup)
end