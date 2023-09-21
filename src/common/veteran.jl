export Veteran, clone, BasicIndiv, VeteranIndiv
export fitness, testscores
export meanfitness

struct FitnessRecord <: Record
    fitness::Float64
end

mutable struct DiscoRecord <: Record
    fitness::Float64
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
    derived_tests::Vector{Float64} = Float64[]
end

mutable struct Veteran{G <: Genotype, R <: Record} <: Individual
    ikey::IndivKey
    geno::G
    pid::Int
    tests::Dict{TestKey, Float64}
    record::R
end

struct IndivKey <: Key
    species_id::String
    indiv_id::Int
end

IndivKey(species_id::String, indiv_id::String) =   IndivKey(species_id, parse(Int, indiv_id))

function fitness(vet::Individual)
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