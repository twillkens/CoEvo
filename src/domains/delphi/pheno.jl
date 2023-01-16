export DelphiPhenoConfig
export DelphiPheno

Base.@kwdef struct DelphiPhenoConfig <: PhenoConfig end

struct DelphiPheno <: Phenotype
    key::String
    traits::Vector{Float64}
end

function(::DelphiPhenoConfig)(geno::VectorGeno{Float64})
    DelphiPheno(geno.key, geno.genes)
end