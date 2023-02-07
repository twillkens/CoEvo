export Outcome
export getscore

struct Outcome{R <: Result, O <: Observation}
    rid::UInt64
    results::Set{R}
    obs::O
end

function Outcome(rid::UInt64, results::Set{<:Result})
    Outcome(rid, results, NullObs())
end

function Outcome(rid::UInt64, r1::Result, r2::Result)
    Outcome(rid, Set([r1, r2]), NullObs())
end

function Outcome(rid::UInt64, r1::Result, r2::Result, obs::Observation)
    Outcome(rid, Set([r1, r2]), obs)
end

function getscore(spkey::String, iid::UInt32, outcome::Outcome)
    rdict = Dict((r.spkey, r.iid) => r for r in outcome.results)
    rdict[(spkey, iid)].score
end