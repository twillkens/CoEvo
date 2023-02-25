export FSMIndiv, FSMGeno, FSMPheno, FSMPhenoCfg
export genotype, LinkDict, StateSet, act, FSMIndivConfig

LinkDict = Dict{Tuple{String, Bool}, String}
StateSet = Set{String}

struct FSMGeno <: Genotype
    ikey::IndivKey
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
        ikey,
        startstate,
        ones,
        zeros,
        LinkDict(((startstate, true) => startstate, (startstate, false) => startstate)))
    FSMIndiv(ikey, geno)
end

function(cfg::FSMIndivConfig)(sc::SpawnCounter, geno::FSMGeno)
    ikey = IndivKey(cfg.spid, iid!(sc))
    geno = FSMGeno(ikey, geno.start, geno.ones, geno.zeros, geno.links)
    FSMIndiv(ikey, geno)
end

function(cfg::FSMIndivConfig)(sc::SpawnCounter, n::Int, geno::FSMGeno)
    ikeys = [IndivKey(cfg.spid, iid!(sc)) for _ in 1:n]
    genos = [FSMGeno(ikey, geno.start, geno.ones, geno.zeros, geno.links) for ikey in ikeys]
    [FSMIndiv(ikey, geno) for (ikey, geno) in zip(ikeys, genos)]
end

function(cfg::FSMIndivConfig)(sc::SpawnCounter, npop::Int, indiv::FSMIndiv)
    ikeys = [IndivKey(cfg.spid, iid!(sc)) for _ in 1:npop]
    genos = [FSMGeno(ikey, indiv.start, indiv.ones, indiv.zeros, indiv.links) for ikey in ikeys]
    [FSMIndiv(ikey, geno) for (ikey, geno) in zip(ikeys, genos)]
end

function(cfg::FSMIndivConfig)(spid::Symbol, iid::Int, childgroup::JLD2.Group)
    geno = FSMGeno(
        IndivKey(spid, iid),
        string(childgroup["start"]),
        Set(string(one) for one in childgroup["ones"]),
        Set(string(zero) for zero in childgroup["zeros"]),
        LinkDict(((source), bit) => target for (source, bit, target) in childgroup["links"]))
    FSMIndiv(ikey, geno)
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
    geno = FSMGeno(ikey, parent.start, parent.ones, parent.zeros, parent.links)
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
    geno = FSMGeno(ikey, start, ones, zeros, links)
    FSMIndiv(ikey, geno)
end

function FSMIndiv(spid::Symbol, iid::UInt32, igroup::JLD2.Group)
    ones = Set(string(o) for o in igroup["ones"])
    zeros = Set(string(z) for z in igroup["zeros"])
    pids = Set(p for p in igroup["pids"])
    start = igroup["start"]
    links = Dict((string(s), w) => string(t) for (s, w, t) in igroup["links"])
    geno = FSMGeno(IndivKey(spid, iid), start, ones, zeros, links)
    FSMIndiv(geno.ikey, geno, pids)
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