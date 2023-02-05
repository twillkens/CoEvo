export PopRole, IndivRole

Base.@kwdef struct PopRole{C <: PhenoConfig}
    role::Symbol
    phenocfg::C
end

struct IndivRole{C <: PhenoConfig} 
    key::String
    role::Symbol
    phenocfg::C
end

function IndivRole(geno::Genotype, poprole::PopRole{C}) where {C <: PhenoConfig}
    IndivRole(geno.key, poprole.role, poprole.phenocfg)
end