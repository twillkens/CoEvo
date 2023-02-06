export Outcome

struct Outcome{R <: Result, O <: Observation}
    rid::Int
    results::Set{R}
    obs::O
end

function Outcome(rid::Int, results::Set{<:Result})
    Outcome(rid, results, NullObs())
end
