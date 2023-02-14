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
    oid::Symbol, ::NGControl, ::NGObsConfig,
    A::Phenotype, B::Phenotype
)
    Outcome(oid, A => true, B => true)
end

function stir(
    oid::Symbol, ::NGGradient, ::NGObsConfig,
    A::ScalarPheno, B::ScalarPheno
)
    Outcome(oid,
        A => A.val > B.val,
        B => B.val > A.val)
end

function stir(
    oid::Symbol, ::NGFocusing, ::NGObsConfig,
    A::VectorPheno, B::VectorPheno
)
    maxdiff, idx = findmax([abs(x1 - x2) for (x1, x2) in zip(A.vec, B.vec)])
    Outcome(oid, 
        A => A.vec[idx] > B.vec[idx],
        B => B.vec[idx] > A.vec[idx])
end

function stir(
    oid::Symbol, ::NGRelativism, ::NGObsConfig,
    A::VectorPheno, B::VectorPheno
)
    mindiff, idx = findmin([abs(x1 - x2) for (x1, x2) in zip(A.vec, B.vec)])
    Outcome(oid,
        A => A.vec[idx] > B.vec[idx],
        B => B.vec[idx] > A.vec[idx])
end

