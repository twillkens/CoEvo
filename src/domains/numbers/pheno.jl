export SumPhenoConfig
export ScalarPheno
export VectorPheno
export SubvecPhenoConfig

struct ScalarPheno{T <: Real} <: Phenotype
    ikey::IndivKey
    val::T
end

function ScalarPheno(spkey::Symbol, iid::UInt32, val::Real)
    ikey = IndivKey(spkey, iid)
    ScalarPheno(ikey, val)
end

function ScalarPheno(spkey::Symbol, iid::Int, val::Real)
    ScalarPheno(spkey, UInt32(iid), val)
end

Base.@kwdef struct SumPhenoConfig <: PhenoConfig
end

function(::SumPhenoConfig)(geno::VectorGeno)
    val = sum(geno.genes)
    ScalarPheno(geno.ikey, val)
end

function(::SumPhenoConfig)(indiv::VectorIndiv)
    val = sum(gene.val for gene in indiv.genes)
    ScalarPheno(indiv.ikey, val)
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
    subvec_width::Int
end

function(::SubvecPhenoConfig)(indiv::VectorIndiv)
    if mod(length(indiv.genes), cfg.subvec_width) != 0
        error("Invalid subvector width for given genome width")
    end

    vec = [sum(part) for part in
        Iterators.partition(map(gene -> gene.val, indiv.genes), cfg.subvec_width)]
    VectorPheno(indiv.ikey, vec)
end

function(cfg::SubvecPhenoConfig)(geno::VectorGeno)
    if mod(length(geno.genes), cfg.subvec_width) != 0
        error("Invalid subvector width for given genome width")
    end
    vec = [sum(part) for part in
        Iterators.partition(geno.genes, cfg.subvec_width)]
    VectorPheno(geno.ikey, vec)
end

