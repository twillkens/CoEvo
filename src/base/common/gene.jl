export ScalarGene

struct ScalarGene{T <: Real} <: Gene
    spkey::String
    gid::Int
    iid::Int
    gen::Int
    val::T
end

function ScalarGene(spkey::String, gid::Int, iid::Int, val::Real)
    ScalarGene(spkey, gid, iid, 1, val)
end