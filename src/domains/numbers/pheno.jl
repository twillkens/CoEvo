export SumPhenoConfig
export ScalarPheno
export VectorPheno
export SubvecPhenoConfig

struct ScalarPheno{T <: Real} <: Phenotype
    ikey::IndivKey
    val::T
end

function ScalarPheno(spkey::Symbol, iid::Real, val::Real)
    ikey = IndivKey(spkey, UInt32(iid))
    ScalarPheno(ikey, val)
end

Base.@kwdef struct SumPhenoConfig <: PhenoConfig
    role::Symbol
end

function(::SumPhenoConfig)(geno::VectorGeno)
    val = sum(geno.genes)
    ScalarPheno(geno.ikey, val)
end

struct VectorPheno{T <: Real} <: Phenotype
    ikey::IndivKey
    vec::Vector{T}
end

function VectorPheno(spkey::Symbol, iid::Real, vec::Vector{<:Real})
    ikey = IndivKey(spkey, UInt32(iid))
    VectorPheno(ikey, vec)
end

Base.@kwdef struct SubvecPhenoConfig <: PhenoConfig
    role::Symbol
    subvec_width::Int
end

function(cfg::SubvecPhenoConfig)(geno::VectorGeno)
    if mod(length(geno.genes), cfg.subvec_width) != 0
        error("Invalid subvector width for given genome width")
    end
    vec = [sum(part) for part in
        Iterators.partition(geno.genes, cfg.subvec_width)]
    VectorPheno(geno.spid, geno.iid, vec)
end

