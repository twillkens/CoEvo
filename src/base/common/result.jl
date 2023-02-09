export ScalarResult, testkey
export MinScalarResult

struct ScalarResult{T} <: Result
    spid::Symbol
    iid::UInt32
    tkey::String
    score::T
end

function testkey(p::Phenotype)
    string(p.spid, KEY_SPLIT_TOKEN, p.iid)
end

function ScalarResult(A::Phenotype, B::Phenotype, score::Real)
    ScalarResult(A.spid, A.iid, testkey(B), score)
end

struct MinScalarResult{T} <: Result
    tkey::String
    score::T
end

function MinScalarResult(res::ScalarResult)
    MinScalarResult(res.tkey, res.score)
end