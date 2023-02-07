export ScalarGene

struct ScalarGene{T <: Real} <: Gene
    gid::UInt32
    iid::UInt32
    gen::UInt16
    val::T
end

function ScalarGene(gid::UInt32, iid::UInt32, val::Real)
    ScalarGene(gid, iid, UInt16(1), val)
end