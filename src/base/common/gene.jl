export ScalarGene

struct ScalarGene{T <: Real} <: Gene
    gid::Int
    iid::Int
    gen::Int
    val::T
end

function ScalarGene(gid::Int, iid::Int, val::Real)
    ScalarGene(gid, iid, 1, val)
end