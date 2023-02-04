export ScalarResult
export ScalarOutcome, ScoreOutcome

struct ScalarResult <: Result
    tkey::String
    score::Float64
end

struct ScalarOutcome <: Outcome
    rid::UInt64
    results::Dict{String, ScalarResult}
end

struct ScoreOutcome <: Outcome
    mixn::Int
    genokey::String
    testkey::String
    role::Symbol
    score::Float64
end