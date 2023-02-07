export stir
export NGObsConfig, NGObs

struct NGObsConfig <: ObsConfig end

struct NGObs <: Observation
    A::VectorPheno
    B::VectorPheno
    maxdiff::Int
    idx::Int
end

function stir(
    rid::Int, ::NGControl, ::NGObsConfig;
    A::Phenotype, B::Phenotype
)
    r1 = ScalarResult(A, B, true)
    r2 = ScalarResult(B, A, true)
    Outcome(rid, Set([r1, r2]))
end

function stir(
    rid::Int, ::NGGradient, ::NGObsConfig;
    A::ScalarPheno, B::ScalarPheno
)
    r1 = ScalarResult(A, B, A.val > B.val)
    r2 = ScalarResult(B, A, B.val > A.val)
    Outcome(rid, r1, r2)
end


function stir(
    rid::Int, ::NGFocusing, ::NGObsConfig;
    A::VectorPheno, B::VectorPheno
)
    v1, v2 = A.vec, B.vec
    maxdiff, idx = findmax([abs(x1 - x2) for (x1, x2) in zip(v1, v2)])
    r1 = ScalarResult(A, B, v1[idx] > v2[idx])
    r2 = ScalarResult(B, A, v2[idx] > v1[idx])
    obs = NGObs(A, B, maxdiff, idx)
    Outcome(rid, r1, r2, obs)
end

function stir(
    rid::Int, ::NGRelativism, ::NGObsConfig;
    A::VectorPheno, B::VectorPheno
)
    v1, v2 = A.vec, B.vec
    maxdiff, idx = findmin([abs(x1 - x2) for (x1, x2) in zip(v1, v2)])
    r1 = ScalarResult(A, B, v1[idx] > v2[idx])
    r2 = ScalarResult(B, A, v2[idx] > v1[idx])
    obs = NGObs(A, B, maxdiff, idx)
    Outcome(rid, r1, r2, obs)
end

