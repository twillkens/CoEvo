export IntPhenoConfig, IntPheno
export VectorPhenoConfig, VectorPheno

Base.@kwdef struct IntPhenoConfig <: PhenoConfig end

struct IntPheno <: Phenotype
    spkey::String
    iid::Int
    val::Int
end

function(::IntPhenoConfig)(geno::VectorGeno)
    val = sum(geno.genes)
    IntPheno(geno.key, val)
end

Base.@kwdef struct VectorPhenoConfig <: PhenoConfig
    subvector_width::Int
end

struct VectorPheno <: Phenotype
    key::String
    traits::Vector{Int}
end

function(cfg::VectorPhenoConfig)(geno::BitstringGeno)
    if mod(length(geno.genes), cfg.subvector_width) != 0
        error("Invalid subvector width for given genome width")
    end
    traits = [sum(part) for part in Iterators.partition(geno.genes, cfg.subvector_width)]
    VectorPheno(geno.key, traits)
end