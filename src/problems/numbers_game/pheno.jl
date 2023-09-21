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

function(::SumPhenoConfig)(ikey::IndivKey, geno::VectorGeno)
    val = sum(geno.genes)
    ScalarPheno(geno.ikey, val)
end




Base.@kwdef struct SubvecPhenoConfig <: PhenoConfig
    subvec_width::Int
end

function(cfg::SubvecPhenoConfig)(indiv::VectorIndiv)
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

