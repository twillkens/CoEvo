export ScalarResult, testkey
export MinScalarResult

struct ScalarResult{T} <: Result
    ikey::IndivKey
    tkey::Recipe
    score::T
end

function ScalarResult(A::Phenotype, B::Phenotype, score::Real)
    ScalarResult(A.ikey, TestKey(B), score)
end

struct MinScalarResult{T} <: Result
    tkey::TestKey
    score::T
end

function MinScalarResult(res::ScalarResult)
    MinScalarResult(res.tkey, res.score)
end