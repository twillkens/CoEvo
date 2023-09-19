export Veteran, clone, BasicIndiv, VeteranIndiv
export fitness, testscores
export meanfitness

struct Veteran{I <: Individual, R <: Real} <: Individual
    ikey::IndivKey
    indiv::I
    rdict::Dict{TestKey, R}
end

function clone(iid::UInt32, parent::Veteran)
    clone(iid, parent.indiv)
end

struct BasicIndiv{G <: Genotype} <: Individual
    ikey::IndivKey
    geno::G
    pid::Int
end

struct VeteranIndiv{G <: Genotype, R <: Real} <: Individual
    ikey::IndivKey
    geno::G
    pid::Int
    rdict::Dict{TestKey, R}
end

function Base.getproperty(indiv::Individual, prop::Symbol)
    if prop == :spid
        indiv.ikey.spid
    elseif prop == :iid
        indiv.ikey.iid
    else
        getfield(indiv, prop)
    end
end

function fitness(vet::Individual)
    length(vet.rdict) == 0 ? 0.0 : sum(values(vet.rdict))
end

function meanfitness(vet::Individual)
    length(vet.rdict) == 0 ? 0.0 : mean(values(vet.rdict))
end

function testscores(vet::Individual)
    SortedDict(r.tkey => r.score for r in vet.results)
end