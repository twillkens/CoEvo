export Outcome

struct Outcome{R <: Result, O <: Observation}
    rid::Int
    results::Set{R}
    obs::O
end

function Outcome(rid::Int, results::Set{<:Result})
    Outcome(rid, results, NullObs())
end

function Outcome(rid::Int, r1::Result, r2::Result)
    Outcome(rid, Set([r1, r2]), NullObs())
end

function Outcome(rid::Int, r1::Result, r2::Result, obs::Observation)
    Outcome(rid, Set([r1, r2]), obs)
end
