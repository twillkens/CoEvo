export ScalarResult, testkey

struct ScalarResult{T} <: Result
    spkey::String
    iid::Int
    tkey::String
    score::T
end

function testkey(p::Phenotype)
    string(p.spkey, KEY_SPLIT_TOKEN, p.iid)
end

function ScalarResult(A::Phenotype, B::Phenotype, score::Real)
    ScalarResult(A.spkey, A.iid, testkey(B), score)
end