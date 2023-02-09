export ScalarGene

struct ScalarGene{T <: Real} <: Gene
    gid::UInt32
    val::T
end
