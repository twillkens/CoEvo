function stir(
    rid::UInt64, ::NGControl, ::NGObsConfig; A::Phenotype, B::Phenotype
)
    r1 = ScalarResult(A, B, true)
    r2 = ScalarResult(B, A, true)
    Outcome(rid, Set([r1, r2]))
end

function stir(
    rid::UInt64, ::NGGradient, ::NGObsConfig; A::IntPheno, B::IntPheno
)
    result = A.val > B.val
    r1 = ScalarResult(A, B, result)
    r2 = ScalarResult(B, A, !result)
    Outcome(rid, Set([r1, r2]))
end

struct NGObsConfig <: ObsConfig end

struct NGObs <: Observation
    A::VectorPheno
    B::VectorPheno
    maxdiff::Int
    idx::Int
end

function stir(
    rid::UInt64, ::NGFocusing, ::NGObsConfig;
    A::VectorPheno, B::VectorPheno
)
    v1, v2 = A.vec, B.vec
    maxdiff, idx = findmax([abs(x1 - x2) for (x1, x2) in zip(v1, v2)])
    result = v1[idx] > v2[idx]
    r1 = ScalarResult(A, B, result)
    r2 = ScalarResult(B, A, !result)
    Outcome(rid, Set([r1, r2]), NGObs(A, B, maxdiff, idx))
end

function stir(
    rid::UInt64, ::NGRelativism, ::NGObsConfig;
    A::VectorPheno, B::VectorPheno
)
    v1, v2 = subject.traits, test.traits
    maxdiff, idx = findmin([abs(x1 - x2) for (x1, x2) in zip(v1, v2)])
    result = v1[idx] > v2[idx]
    r1 = ScalarResult(A, B, result)
    r2 = ScalarResult(B, A, !result)
    Outcome(rid, Set([r1, r2]), NGObs(A, B, maxdiff, idx))
end

