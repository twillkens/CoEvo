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
    oid::Symbol, ::NGControl, ::NGObsConfig;
    A::Phenotype, B::Phenotype
)
    Outcome(oid, Dict(A.ikey => true, B.ikey => true))
end

function stir(
    oid::Symbol, ::NGGradient, ::NGObsConfig;
    A::ScalarPheno, B::ScalarPheno
)
    # for i in 1:A.val*256
        # tanh(rand())
    # end

    # for i in 1:B.val
        # tanh(rand())*256
    # end

    Outcome(oid, Dict(
        A.ikey => A.val > B.val,
        B.ikey => B.val > A.val))
end


function stir(
    oid::Symbol, ::NGFocusing, ::NGObsConfig;
    A::VectorPheno, B::VectorPheno
)
    maxdiff, idx = findmax([abs(x1 - x2) for (x1, x2) in zip(A.vec, B.vec)])
    Outcome(oid, Dict(
        A.ikey => A.vec[idx] > B.vec[idx],
        B.ikey => B.vec[idx] > A.vec[idx]))
end

function stir(
    oid::Symbol, ::NGRelativism, ::NGObsConfig;
    A::VectorPheno, B::VectorPheno
)
    maxdiff, idx = findmin([abs(x1 - x2) for (x1, x2) in zip(A.vec, B.vec)])
    Outcome(oid, Dict(
        A.ikey => A.vec[idx] > B.vec[idx],
        B.ikey => B.vec[idx] > A.vec[idx]))
end

