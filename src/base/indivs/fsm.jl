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
end


Base.@kwdef struct FSMIndivConfig <: IndivConfig
    spid::Symbol
    sc::SpawnCounter
    rng::AbstractRNG
end

function(cfg::FSMIndivConfig)()
    ikey = IndivKey(cfg.spid, iid!(cfg.sc))
    startstate = string(gid!(cfg.sc))
    geno = FSMGeno(
        ikey,
        startstate,
        Set([startstate]),
        Set{String}(),
        LinkDict(((startstate, true) => startstate, (startstate, false) => startstate)))
    FSMIndiv(ikey, geno)
end

function(cfg::FSMIndivConfig)(geno::FSMGeno)
    FSMIndiv(geno.ikey, geno)
end


function(cfg::FSMIndivConfig)(geno::FSMGeno)
    ikey = IndivKey(cfg.spid, iid!(cfg.sc))
    geno = FSMGeno(ikey, geno.start, geno.ones, geno.zeros, geno.links)
    FSMIndiv(ikey, geno)
end

function(cfg::FSMIndivConfig)(n::Int, geno::FSMGeno)
    ikeys = [IndivKey(cfg.spid, iid!(cfg.sc)) for _ in 1:n]
    genos = [FSMGeno(ikey, geno.start, geno.ones, geno.zeros, geno.links) for ikey in ikeys]
    [FSMIndiv(ikey, geno) for (ikey, geno) in zip(ikeys, genos)]
end

function(cfg::FSMIndivConfig)(npop::Int, indiv::FSMIndiv)
    ikeys = [IndivKey(cfg.spid, iid!(cfg.sc)) for _ in 1:npop]
    genos = [FSMGeno(ikey, indiv.start, indiv.ones, indiv.zeros, indiv.links) for ikey in ikeys]
    [FSMIndiv(ikey, geno) for (ikey, geno) in zip(ikeys, genos)]
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
    FSMIndiv(ikey, FSMGeno(ikey, parent.start, parent.ones, parent.zeros, parent.links))
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

function FSMIndiv(ikey::IndivKey)
    start = "1"
    ones, zeros = rand(Bool) ? (Set([start]), Set()) : (Set(), Set([start]))
    links = LinkDict((start, true) => start, (start, false) => start)
    geno = FSMGeno(ikey, start, ones, zeros, links)
    FSMIndiv(ikey, geno)
end

function FSMIndiv(
    ikey::IndivKey, start::String, ones::Set{String}, zeros::Set{String}, links::LinkDict
)
    geno = FSMGeno(ikey, start, ones, zeros, links)
    FSMIndiv(ikey, geno)
end
