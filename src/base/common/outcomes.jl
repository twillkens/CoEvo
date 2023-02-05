export ScalarResult
export Outcome

struct ScalarResult{T} <: Result
    spkey::String
    iid::Int
    tkey::String
    score::T
end

function ScalarResult(A::Phenotype, B::Phenotype, score::Real)
    ScalarResult(A.spkey, A.iid, testkey(B), score)
end

struct Outcome{O <: Observation}
    rid::UInt64
    results::Set{ScalarResult}
    obs::O
end

struct NullObs <: Observation
end

function Outcome(rid::UInt64, results::Dict{String, ScalarResult})
    Outcome(rid, results, NullObs())
end
