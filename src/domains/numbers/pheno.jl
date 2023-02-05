export SumPhenoConfig
export ScalarPheno
export VectorPheno
export SubvecPhenoConfig

struct ScalarPheno{T <: Real} <: Phenotype
    spkey::String
    iid::Int
    val::T
end

Base.@kwdef struct SumPhenoConfig <: PhenoConfig end

function(::SumPhenoConfig)(geno::VectorGeno)
    val = sum(geno.genes)
    ScalarPheno(geno.spkey, geno.iid, val)
end

struct VectorPheno{T <: Real} <: Phenotype
    spkey::String
    iid::Int
    vec::Vector{T}
end

Base.@kwdef struct SubvecPhenoConfig <: PhenoConfig
    subvec_width::Int
end

function(cfg::SubvecPhenoConfig)(geno::VectorGeno)
    if mod(length(geno.genes), cfg.subvec_width) != 0
        error("Invalid subvector width for given genome width")
    end
    vec = [sum(part) for part in
        Iterators.partition(geno.genes, cfg.subvec_width)]
    VectorPheno(geno.spkey, geno.iid, vec)
end