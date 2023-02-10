export Outcome
export getscore

struct Outcome{R, O <: Observation}
    oid::Symbol
    rdict::Dict{IndivKey, R}
    obs::O
end

function Outcome(oid::Symbol, rdict::Dict{IndivKey, R}) where R
    Outcome(oid, rdict, NullObs())
end

function Outcome(oid::Symbol, r1::Pair{IndivKey, R}, r2::Pair{IndivKey, R}) where R
    Outcome(oid, Dict(r1, r2), NullObs())
end

function Outcome(
    oid::Symbol, r1::Pair{IndivKey, R}, r2::Pair{IndivKey, R}, obs::Observation
) where R
    Outcome(oid, Dict(r1, r2), obs)
end

function getscore(ikey::IndivKey, o::Outcome)
    o.rdict[ikey]
end

function getscore(spkey::Symbol, iid::Real, o::Outcome)
    getscore(IndivKey(spkey, iid), o)
end

function getresults(o::Outcome)
    Set([ScalarResult(ikey, o.oid, r.score) for (ikey, r) in o.rdict])
end