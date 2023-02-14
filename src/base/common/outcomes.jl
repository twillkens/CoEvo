export Outcome
export getscore


struct Outcome{R, O <: Observation}
    oid::Symbol
    rdict::Dict{IndivKey, Pair{TestKey, R}}
    obs::O
end

function Outcome(oid::Symbol, rdict::Dict{IndivKey, Pair{TestKey, R}}) where R
    Outcome(oid, rdict, NullObs())
end


function Outcome(oid::Symbol, pr1::Pair{<:Phenotype, R}, pr2::Pair{<:Phenotype, R}) where R
    Outcome(oid, Dict(
        pr1.first.ikey => TestKey(oid, pr2.first.ikey) => pr1.second,
        pr2.first.ikey => TestKey(oid, pr1.first.ikey) => pr2.second))
end

function Outcome(
    oid::Symbol, pr1::Pair{<:Phenotype, R}, pr2::Pair{<:Phenotype, R}, obs::Observation) where R

    Outcome(oid, Dict(
        pr1.first.ikey => TestKey(oid, pr2.first.ikey) => pr1.second,
        pr2.first.ikey => TestKey(oid, pr1.first.ikey) => pr2.second), obs)
end

function getscore(ikey::IndivKey, o::Outcome)
    o.rdict[ikey].second
end

function getscore(spkey::Symbol, iid::Real, o::Outcome)
    getscore(IndivKey(spkey, iid), o)
end