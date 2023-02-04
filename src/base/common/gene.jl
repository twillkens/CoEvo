export ScalarGene

struct ScalarGene{T <: Real} <: Gene
    gid::Int
    iid::Int
    gen::Int
    val::T
end