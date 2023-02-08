export ScalarGene

struct ScalarGene{T <: Real} <: Gene
    gid::UInt32
    val::T
end

function ScalarGene(gid::UInt32, val::Real)
    ScalarGene(gid, val)
end