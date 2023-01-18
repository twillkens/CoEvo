export TestPairOutcome
export ScalarOutcome, ScalarResult
export getscore

struct TestPairOutcome <: PairOutcome
    n::Int
    subject_key::String
    test_key::String
    scores::Dict{String, Union{Float64, Nothing}}
end

struct ScalarResult
    key::String
    testkey::String
    role::Symbol
    score::Union{Float64, Nothing}
end

function ScalarResult(genokey::String, role::Symbol, score::Union{Float64, Nothing})
    ScalarResult(genokey, "", role, score)
end

struct ScalarOutcome <: Outcome
    n::Int
    results::Set{ScalarResult}
end

function Dict{Symbol, ScalarResult}(outcome::ScalarOutcome)
    Dict([r.role => r for r in outcome.results])
end

function Dict{String, ScalarResult}(outcome::ScalarOutcome)
    Dict([r.key => r for r in outcome.results])
end

function ScalarResult(role::Symbol, outcome::ScalarOutcome)
    Dict{Symbol, ScalarResult}(outcome)[role]
end

function ScalarResult(key::String, outcome::ScalarOutcome)
    Dict{String, ScalarResult}(outcome)[key]
end

function getscore(key::String, outcome::ScalarOutcome)
    ScalarResult(key, outcome).score
end

function getscore(role::Symbol, outcome::ScalarOutcome)
    ScalarResult(role, outcome).score
end