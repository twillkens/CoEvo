
LinkDict = Dict{Tuple{String, Bool}, String}
StateSet = Set{String}

struct FSMGeno <: Genotype
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

function Base.getproperty(indiv::FSMIndiv, s::Symbol)
    if s == :geno
        return indiv.geno
    elseif s == :ones
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
