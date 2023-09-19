export Veteran, clone, BasicIndiv, VeteranIndiv
export fitness, testscores
export meanfitness

Base.@kwdef mutable struct Veteran{I <: Individual, R <: Real} <: Individual
    ikey::IndivKey
    indiv::I
    rdict::Dict{TestKey, R}
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
    derived_tests::Vector{Float64} = Float64[]
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
    #println("---------$(vet.ikey.spid)-----------")
    #println(round.(values(vet.rdict); digits=2))
    length(vet.rdict) == 0 ? 0.0 : sum(values(vet.rdict))
end

function meanfitness(vet::Individual)
    length(vet.rdict) == 0 ? 0.0 : mean(values(vet.rdict))
end

function testscores(vet::Individual)
    SortedDict(r.tkey => r.score for r in vet.results)
end

function makevets(
    indivs::Dict{IndivKey, I}, resdict::Dict{IndivKey, Vector{Pair{TestKey, R}}}
) where {I <: Individual, R <: Real}
    checkd = ikey -> ikey in keys(resdict) ? Dict(resdict[ikey]) : Dict{TestKey, R}()
    VeteranIndiv[VeteranIndiv(indiv.ikey, indiv.geno, indiv.pid, checkd(indiv.ikey)) for indiv in values(indivs)]
end

function makevets(allsp::Dict{Symbol, <:Species}, outcomes::Vector{<:Outcome})
    resdict = makeresdict(outcomes)
    Dict(spid => 
        Species(
            spid,
            sp.phenocfg,
            makevets(sp.pop, resdict),
            makevets(sp.children, resdict))
    for (spid, sp) in allsp)
end

function makeresdict(outcomes::Vector{Outcome{R, O}}) where {R <: Real, O <: Observation}
    resdict = Dict{IndivKey, Vector{Pair{TestKey, R}}}()
    for outcome in outcomes
        for (ikey, pair) in outcome.rdict
            if ikey in keys(resdict)
                push!(resdict[ikey], pair)
            else
                resdict[ikey] = [pair]
            end
        end
    end
    resdict
end