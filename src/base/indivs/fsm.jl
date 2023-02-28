export FSMIndiv, FSMGeno, FSMPheno, FSMPhenoCfg
export genotype, LinkDict, StateSet, act, FSMIndivConfig

LinkDict = Dict{Tuple{String, Bool}, String}
StateSet = Set{String}

struct FSMGeno <: Genotype
    start::String
    ones::Set{String}
    zeros::Set{String}
    links::LinkDict
end

struct FSMPheno <: Phenotype
    ikey::IndivKey
    start::String
    ones::Set{String}
    zeros::Set{String}
    links::LinkDict
end

struct FSMIndiv <: Individual
    ikey::IndivKey
    geno::FSMGeno
    pids::Set{UInt32}
end

function FSMIndiv(ikey::IndivKey, geno::FSMGeno)
    FSMIndiv(ikey, geno, Set{UInt32}())
end

function FSMIndiv(spid::Symbol, iid::UInt32, geno::FSMGeno, pids::Set{UInt32})
    FSMIndiv(IndivKey(spid, iid), geno, pids)
end

Base.@kwdef struct FSMIndivConfig <: IndivConfig
    spid::Symbol
    itype::Type{<:Individual} = FSMIndiv
end

function(cfg::FSMIndivConfig)(rng::AbstractRNG, sc::SpawnCounter)
    ikey = IndivKey(cfg.spid, iid!(sc))
    startstate = string(gid!(sc))
    ones, zeros = rand(rng, Bool) ?
        (Set([startstate]), Set{String}()) : (Set{String}(), Set([startstate]))
    geno = FSMGeno(
        startstate,
        ones,
        zeros,
        LinkDict(((startstate, true) => startstate, (startstate, false) => startstate)))
    FSMIndiv(ikey, geno)
end

function(cfg::FSMIndivConfig)(sc::SpawnCounter, geno::FSMGeno)
    ikey = IndivKey(cfg.spid, iid!(sc))
    geno = FSMGeno(geno.start, geno.ones, geno.zeros, geno.links)
    FSMIndiv(ikey, geno)
end

function(cfg::FSMIndivConfig)(sc::SpawnCounter, n::Int, geno::FSMGeno)
    ikeys = [IndivKey(cfg.spid, iid!(sc)) for _ in 1:n]
    genos = [FSMGeno(geno.start, geno.ones, geno.zeros, geno.links) for ikey in ikeys]
    [FSMIndiv(ikey, geno) for (ikey, geno) in zip(ikeys, genos)]
end

function(cfg::FSMIndivConfig)(sc::SpawnCounter, npop::Int, indiv::FSMIndiv)
    ikeys = [IndivKey(cfg.spid, iid!(sc)) for _ in 1:npop]
    genos = [FSMGeno(indiv.start, indiv.ones, indiv.zeros, indiv.links) for ikey in ikeys]
    [FSMIndiv(ikey, geno) for (ikey, geno) in zip(ikeys, genos)]
end

function(cfg::FSMIndivConfig)(spid::Symbol, iid::Int, childgroup::JLD2.Group)
    geno = FSMGeno(
        string(childgroup["start"]),
        Set(string(one) for one in childgroup["ones"]),
        Set(string(zero) for zero in childgroup["zeros"]),
        LinkDict(((source), bit) => target for (source, bit, target) in childgroup["links"]))
    FSMIndiv(spid, iid, geno, childgroup["pids"])
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

function genotype(indiv::FSMIndiv)
    indiv.geno
end

function clone(iid::UInt32, parent::FSMIndiv)
    ikey = IndivKey(parent.spid, iid)
    geno = FSMGeno(parent.start, parent.ones, parent.zeros, parent.links)
    FSMIndiv(ikey, geno, Set([parent.iid]))
end

struct FSMPhenoCfg <: PhenoConfig
end

function(cfg::FSMPhenoCfg)(geno::FSMGeno)
    FSMPheno(geno.ikey, geno.start, geno.ones, geno.zeros, geno.links)
end

function(cfg::FSMPhenoCfg)(indiv::FSMIndiv)
    FSMPheno(indiv.ikey, indiv.start, indiv.ones, indiv.zeros, indiv.links)
end

function FSMIndiv(spid::Symbol, iid::UInt32, geno::FSMGeno)
    FSMIndiv(IndivKey(spid, iid), geno)
end

function FSMIndiv(
    ikey::IndivKey, start::String, ones::Set{String}, zeros::Set{String}, links::LinkDict
)
    geno = FSMGeno(start, ones, zeros, links)
    FSMIndiv(ikey, geno)
end


function FSMIndiv(spid::Symbol, iid::String, igroup::JLD2.Group)
    FSMIndiv(spid, parse(UInt32, iid), igroup)
end

function FSMIndiv(spid::String, iid::String, igroup::JLD2.Group)
    FSMIndiv(Symbol(spid), parse(UInt32, iid), igroup)
end

function FSMIndiv(ikey::IndivKey, igroup::JLD2.Group)
    FSMIndiv(ikey.spid, ikey.iid, igroup)
end

Base.@kwdef struct FSMIndivArchiver <: Archiver
    interval::Int = 1
    log_popids::Bool = false
    minimize::Bool = true
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

function FSMIndiv(spid::Symbol, iid::UInt32, igroup::JLD2.Group)
    ones = igroup["ones"]
    zeros = igroup["zeros"]
    pids = igroup["pids"]
    start = igroup["start"]
    links = Dict(
        (s, w) => t for (s, w, t) in zip(igroup["sources"], igroup["bits"], igroup["targets"])
    )
    geno = FSMGeno(start, ones, zeros, links)
    FSMIndiv(spid, iid, geno, pids)
end